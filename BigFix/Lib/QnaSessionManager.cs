using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Security.Cryptography;
using System.Threading.Tasks;
using System.Text;

namespace BigFix.Qna
{
  public class Result
  {
    private string _hash = null;

    public string Relevance { get; private set; }
    public string[] Answer { get; private set; }
    public string Error { get; private set; }
    public long EvalTime { get; private set; }

    bool IsError { get { return this.Error != null; } }

    public Result(string Relevance, string[] Answer, string Error, long EvalTime)
    {
      this.Relevance = Relevance;
      this.Answer = Answer;
      this.Error = Error;
      this.EvalTime = EvalTime;
    }

    public string GetHash()
    {
      if (this._hash == null)
      {
        using (SHA256 hashAlgorithm = SHA256.Create())
        {
          byte[] hash = hashAlgorithm.ComputeHash(Encoding.UTF8.GetBytes(this.Relevance));

          StringBuilder hashString = new StringBuilder();

          for (int i = 0; i < hash.Length; i++)
          {
            hashString.Append(hash[i].ToString("x2"));
          }

          this._hash = hashString.ToString();
        }
      }

      return this._hash;
    }

    public override string ToString()
    {
      StringBuilder output = new StringBuilder();
      output.AppendFormat("Q: {0}\n", Relevance);
      foreach (string answer in Answer)
      {
        output.AppendFormat("A: {0}\n", answer);
      }
      if (IsError)
      {
        output.AppendFormat("E: {0}\n", Error);
      }
      output.AppendFormat("T: {0}\n", TimeSpan.FromMilliseconds(EvalTime));

      return output.ToString();
    }
  }

  public class Session : IDisposable
  {
    /// <summary>
    /// Default name of an environmental variable that can be set to define the location
    /// where the BigFix QnA executable is installed.
    /// </summary>
    const string DEFAULT_QNA_ENVIRONMENTAL_VARIABLE = "QnA";

    /// <summary>
    /// Default name of the BigFix QnA executable if one was not provided.
    /// </summary>
    const string DEFAULT_QNA_EXECUTABLE = "qna.exe";

    /// <summary>
    /// Default amount of time (in seconds) to wait for the QnA process to return a result
    /// before considering it not-responsive.
    /// </summary>
    const int DEFAULT_QNA_EVALUATION_TIMEOUT = 60;

    /// <summary>
    /// Default amount of time (in milliseconds) the idle monitor will sleep between checking
    /// if a timeout event occurred. Values over 1,000 should be avoided as it could cause the
    /// idle timeout interval to exceed the 1-second granularity accuracy implied.
    /// </summary>
    const int DEFAULT_QNA_IDLE_POLLING = 300;

    /// <summary>
    /// Default amount of time (in seconds) the idle monitor will wait before stopping the
    /// spawned QnA process due to inactivity.
    /// </summary>
    const int DEFAULT_QNA_IDLE_TIMEOUT = 300;

    private readonly Object _lock = new object();

    private Process _process;
    private DateTime _lastActivity;
    private TimeSpan _idleTimeout;
    private TimeSpan _evaluationTimeout;
    private Task _monitor;
    private bool _evaluating;

    /// <summary>
    /// Amount of time (in seconds) to keep the QnA process running while waiting
    /// for new queries.
    /// </summary>
    public int IdleTimeout
    {
      get { return (int)_idleTimeout.TotalSeconds; }
      set
      {
        lock (_lock)
        {
          _idleTimeout = TimeSpan.FromSeconds(value);
        }
      }
    }

    /// <summary>
    /// Amount of time (in seconds) to wait for the QnA process to evaluate a query
    /// before considering it not-responsive.
    /// </summary>
    public int EvaluationTimeout
    {
      get { return (int)_evaluationTimeout.TotalSeconds; }
      set
      {
        lock (_lock)
        {
          _evaluationTimeout = TimeSpan.FromSeconds(value);
        }
      }
    }

    /// <summary>
    /// Full path to the BigFix QnA executable.
    /// </summary>
    public string ExecutablePath { get; private set; }

    /// <summary>
    /// Version of the BigFix QnA executable.
    /// </summary>
    public string Version { get; private set; }

    public Session() : this(null) { }
    public Session(string path)
    {
      EvaluationTimeout = DEFAULT_QNA_EVALUATION_TIMEOUT;
      IdleTimeout = DEFAULT_QNA_IDLE_TIMEOUT;

      SetExecutablePath(path);

      if (!SpawnQnaProcess())
      {
        throw new Exception("Unable to spawn BigFix QnA process!");
      }
    }

    private async Task ProcessIdleMonitor()
    {
      try
      {
        while (true)
        {
          DateTime now = DateTime.Now;
          TimeSpan elapsedTime = now - _lastActivity;

          if (_process != null && _evaluating != true && elapsedTime >= _idleTimeout)
          {
            lock (_lock)
            {
              try
              {
                _process.Kill();
                _process.Dispose();
              }
              catch (ObjectDisposedException) { }
              catch (InvalidOperationException)
              {
                _process.Dispose();
                _process = null;
              }
              catch (Win32Exception)
              {
                _process.Dispose();
                _process = null;
              }
              finally
              {
                _process = null;
              }
            }
          }

          await Task.Delay(DEFAULT_QNA_IDLE_POLLING);
        }
      }
      finally
      {
        lock (_lock)
        {
          try
          {
            if (_process != null)
            {
              if (_process.HasExited == true)
              {
                _process.Dispose();
                _process = null;
              }
              if (_process.Responding == false)
              {
                _process.Kill();
                _process.Dispose();
                _process = null;
              }
            }
          }
          catch (ObjectDisposedException)
          {
            _process = null;
          }
          catch (InvalidOperationException)
          {
            _process.Dispose();
            _process = null;
          }
          catch (Win32Exception)
          {
            _process.Dispose();
            _process = null;
          }
        }
      }
    }

    private bool SpawnQnaProcess()
    {
      lock (_lock)
      {
        _lastActivity = DateTime.Now;

        try
        {
          if (_process != null)
          {
            if (_process.HasExited == true)
            {
              _process.Dispose();
              _process = null;
            }
            if (_process.Responding == false)
            {
              _process.Kill();
              _process.Dispose();
              _process = null;
            }
          }
        }
        catch (ObjectDisposedException)
        {
          _process = null;
        }
        catch (InvalidOperationException)
        {
          _process.Dispose();
          _process = null;
        }
        catch (Win32Exception)
        {
          _process.Dispose();
          _process = null;
        }
      }

      if (_process == null)
      {
        Process process = null;
        try
        {
          process = new Process();
          process.StartInfo.FileName = this.ExecutablePath;
          process.StartInfo.RedirectStandardInput = true;
          process.StartInfo.RedirectStandardOutput = true;
          process.StartInfo.CreateNoWindow = true;
          process.StartInfo.UseShellExecute = false;
          process.StartInfo.ErrorDialog = false;

          if (process.Start())
          {
            process.StandardInput.AutoFlush = true;
            lock (_lock)
            {
              _process = process;

              if (_monitor == null || _monitor.IsCompleted)
              {
                _monitor = ProcessIdleMonitor();
              }
            }

            return true;
          }
          else
          {
            process.Kill();
            process.Dispose();
          }
        }
        catch
        {
          return false;
        }

        return false;
      }

      return _process != null ? _process.Responding == true : false;
    }

    private bool SetExecutablePath()
    {
      List<string> searchPaths = new List<string>();

      // Environmental variable.
      searchPaths.Add(Environment.ExpandEnvironmentVariables(Environment.GetEnvironmentVariable(DEFAULT_QNA_ENVIRONMENTAL_VARIABLE) ?? String.Empty));

      // Current working directory.
      searchPaths.Add(Directory.GetCurrentDirectory());

      // Look to see if the BigFix Client is installed as the QnA utility is [typically] co-installed along side.
      searchPaths.Add(Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\BigFix\EnterpriseClient", "EnterpriseClientFolder", Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\BigFix\EnterpriseClient", "EnterpriseClientFolder", null)) as string);

      // System environmental search path(s).
      searchPaths.AddRange(Environment.ExpandEnvironmentVariables(Environment.GetEnvironmentVariable("PATH") ?? String.Empty).Split(new char[] { ';' }));

      foreach (string path in searchPaths)
      {
        if (!String.IsNullOrWhiteSpace(path))
        {
          if (SetExecutablePath(path))
          {
            return true;
          }
        }
      }

      return false;
    }

    private bool SetExecutablePath(string path)
    {
      if (String.IsNullOrWhiteSpace(path))
      {
        return SetExecutablePath();
      }

      string executablePath = null;

      if (".exe".Equals(Path.GetExtension(path), StringComparison.InvariantCultureIgnoreCase))
      {
        executablePath = path;
      }
      else
      {
        executablePath = Path.Combine(path, DEFAULT_QNA_EXECUTABLE);
      }

      if (File.Exists(executablePath))
      {
        try
        {
          var fileInfo = FileVersionInfo.GetVersionInfo(executablePath);

          if (fileInfo != null && (fileInfo.ProductName.Contains("QnA") || fileInfo.FileDescription.Contains("QnA")))
          {
            ExecutablePath = executablePath;
            Version = fileInfo.ProductVersion;

            return true;
          }
        }
        catch { }
      }

      return false;
    }

    public Result Query(string relevance)
    {
      List<string> answers = new List<string>();
      string error = null;
      long evalTime = 0;

      try
      {
        if (SpawnQnaProcess())
        {
          lock (_lock)
          {
            _evaluating = true;
          }

          _process.StandardInput.WriteLine(relevance);

          while (true)
          {
            string line = _process.StandardOutput.ReadLine();

            if (line.StartsWith("Q: "))
            {
              line = line.Substring(3);
            }

            if (String.IsNullOrWhiteSpace(line))
            {
              break;
            }

            switch (line[0])
            {
              case 'A':
                answers.Add(line.Substring(3));
                break;
              case 'E':
                error = line.Substring(3);
                break;
              case 'T':
                if (!long.TryParse(line.Substring(3), out evalTime))
                {
                  evalTime = 0;
                }
                break;
            }
          }
        }
        else
        {
          error = "Unable to spawn BigFix QnA process!";
        }
      }
      catch (Exception e)
      {
        error = e.Message;
      }
      finally
      {
        lock (_lock)
        {
          _evaluating = false;
          _lastActivity = DateTime.Now;
        }
      }

      return new Result(relevance, answers.ToArray(), error, evalTime);
    }

    public void Dispose()
    {
      if (_process != null)
      {
        lock (_lock)
        {
          _process.Kill();
          _process.Dispose();
        }
      }

      try
      {
        if (_monitor != null)
        {
          if (_monitor.IsCompleted == false)
          {
            _monitor.Wait(DEFAULT_QNA_IDLE_POLLING);
          }
        }
      }
      catch { }
    }
  }

}