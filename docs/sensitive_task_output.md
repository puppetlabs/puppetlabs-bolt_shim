# Sensitive task output

When you run a task from a plan using the `pcp` transport, sensitive output is
not supported. Although results from tasks that include sensitive output will
still include a `_sensitive` key, it is not possible to unwrap this value. This
is because the sensitive value is not stored in the Orchestrator database and
the Orchestrator task function returns the string `Sensitive: [value redacted]`.

For example, the following task returns a sensitive value:

```bash
#!/bin/sh
echo '{"_sensitive":"$3cr3tp@$$word!"}'
```

The following plan runs the task and attempts to unwrap the sensitive value:

```puppet
plan sensitive_output (
  TargetSpec $targets
) {
  $result = run_task('sensitive_output', $targets).first
  out::message("The secret is: ${result.sensitive.unwrap})
}
```

Running this plan using the `pcp` transport results in an error similar to this:

```console
'unwrap' parameter 'arg' expects a Sensitive value, got String
```

This happens because the Orchestrator task function returned a string value for
the sensitive output. When the plan attempts to unwrap this value using
`$result.sensitive.unwrap`, the plan fails due a type mismatch error.
