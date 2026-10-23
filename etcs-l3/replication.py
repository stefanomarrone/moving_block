import concurrent.futures
import subprocess
import time
import psutil


def execute_bash_command(command):
    start_time = time.time()
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    pid = process.pid

    memory_usage = []
    try:
        proc = psutil.Process(pid)
        while process.poll() is None:
            mem_info = proc.memory_info()
            memory_usage.append(mem_info.rss)  # RSS (Resident Set Size)
            time.sleep(0.1)  # Sample memory usage every 0.1 seconds

        stdout, stderr = process.communicate()
        end_time = time.time()

        execution_time = end_time - start_time
        max_memory_usage = max(memory_usage) if memory_usage else 0

        return {
            'command': command,
            'execution_time': execution_time,
            'max_memory_usage': max_memory_usage,
            'stdout': stdout.decode('utf-8'),
            'stderr': stderr.decode('utf-8')
        }
    except psutil.NoSuchProcess:
        return {
            'command': command,
            'execution_time': None,
            'max_memory_usage': None,
            'stdout': None,
            'stderr': "Process terminated unexpectedly"
        }


def run_commands_in_parallel(commands):
    results = []
    with concurrent.futures.ProcessPoolExecutor() as executor:
        futures = {executor.submit(execute_bash_command, cmd): cmd for cmd in commands}
        for future in concurrent.futures.as_completed(futures):
            cmd = futures[future]
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                results.append({
                    'command': cmd,
                    'execution_time': None,
                    'max_memory_usage': None,
                    'stdout': None,
                    'stderr': str(e)
                })
    return results

def run_commands_in_serie(commands):
    results = []
    for command in commands:
        try:
            result = execute_bash_command(command)
            results.append(result)
        except Exception as e:
            results.append({
                'command': command,
                'execution_time': None,
                'max_memory_usage': None,
                'stdout': None,
                'stderr': str(e)
            })
    return results


# Example usage
if __name__ == '__main__':
    commands = [
        'gprolog --consult-file system.pl --query-goal "nominal([t1, t2], L), print_log(L), halt"',
        'gprolog --consult-file system.pl --query-goal "hazard([t1, t2], L), print_log(L), halt"',
        'gprolog --consult-file system.pl --query-goal "accident([t1, t2], L), print_log(L), halt"',
    ]
    results = run_commands_in_serie(commands)
    handler = open("results.log", "w")
    for result in results:
        handler.write(str(result))
        print(result)
    handler.close()