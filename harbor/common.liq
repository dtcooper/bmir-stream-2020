def error(s)
    print(s)
    log(s)
    exit(1)
end

def conf(name, ~allow_empty=false)
    value = getenv(name)
    if not allow_empty and value == '' then
        error('Configuration value "#{name}" not set. Consider running with '
              ^ '"./run.sh" to set environment. Shutting down.')
    end
    value
end

def conf.list(name, ~allow_empty=false, ~default=[])
    value = of_json(default=default, conf(allow_empty=allow_empty, name))
    if not allow_empty and list.length(value) == 0 then
        error('Configuration value "#{name}" empty list. Shutting down.')
    end
    value
end

def conf.int(name)
    int_of_string(conf(name))
end

def conf.float(name)
    float_of_string(conf(name))
end

def conf.bool(name)
    value = string.case(string.trim(conf(allow_empty=true, name)))
    not (value == '' or value == 'false' or value == 'f' or value == '0')
end

daemonize = argv(1) != ""
script_name = if daemonize then argv(1) else 'default' end
if daemonize then
    set('log.file', true)
    set('log.file.path', '/var/log/liquidsoap/#{script_name}.log')
    set('log.file.perms', 416)
end

if file.exists('/.dockerenv') then
    # Docker only! Otherwise always localhost.
    set('server.telnet.bind_addr', '0.0.0.0')
end

git_rev = string.trim(get_process_output('git rev-parse HEAD'))
git_rev = if git_rev == '' then
    'unknown'
else
    string.sub(git_rev, start=string.length(git_rev) - 8, length=8)
end

server.register('ping', usage='ping', description='Get a pong back from the server', fun(_) -> 'pong')
