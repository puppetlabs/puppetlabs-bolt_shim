# Connecting Bolt to PE

Although it's possible to connect Bolt to Puppet Enterprise (PE) using the
Puppet Communications Protocol (PCP) transport, in most cases this is not
necessary, because tasks and plans are already supported from the console or the
command line using
[PE orchestrator](https://puppet.com/docs/pe/latest/running_jobs_with_puppet_orchestrator_overview.html).
Wherever possible, we recommend using PE tasks and plans instead of connecting
Bolt to PE over PCP. For more information, see [Tasks and
plans](https://puppet.com/docs/pe/2019.8/running_tasks_and_plans_pe.html).

For some Bolt features, connecting Bolt to PE over PCP requires the `bolt_shim`
module. Before you attempt to use the `bolt_shim` module, note that:   
- If you're only interested in using Bolt tasks, you can use the PCP transport
  without the `bolt_shim` module.
- In order to use Bolt plan functionality like commands, scripts or file uploads
  over PCP, you must install the `bolt_shim` module. Basic plans without
  commands, scripts or file uploads do not require the module to function over
  PCP.
- The `bolt_shim` module requires you to grant permissions to run all tasks on
  all nodes to any user that needs to use the module. **This grants those users
  the ability to run any command as root on the nodes. Use this configuration at
  your own risk.**

You might want to use the PCP transport for the following reasons:
- You want to use a Bolt feature that isn't supported in PE yet. Many of the
  features that are available in Bolt eventually make it into the Puppet
  orchestrator and PE.
- You want to develop and test Bolt plans locally and can't use SSH or WinRM
  to do so. If you do have access, you can use SSH or WinRM to test locally.
- You want to interact with nodes attached to different PE instances at the
  same time. For example, if you have different PE instances running for
  different teams and you want to orchestrate change across all of the
  instances. You can achieve this by setting up an inventory file with groups of
  targets, and configuring the `pcp` transport differently for each group. For more
  information, see the [Bolt Transport configuration
  reference](https://puppet.com/docs/bolt/latest/bolt_transports_reference.html#pcp)
  for `pcp`.

## How it works

Using the `bolt_shim` module, you can configure Bolt to use the orchestrator API
and perform actions on PE nodes. When you run Bolt plans, the plan logic is
processed locally on the node running Bolt, while corresponding commands,
scripts, tasks, and file uploads run remotely using the orchestrator API.

## Connecting Bolt to PE

Before you can connect Bolt to PE, you must [install
Bolt](https://puppet.com/docs/bolt/latest/bolt_installing.html).

To set up Bolt to use the orchestrator API, you must:
-   Install the `bolt_shim` module in a PE environment.
-   Assign permissions to run all tasks on all nodes to a user role.
-   Adjust the orchestrator configuration files, as needed.
-   Configure Bolt to connect to PuppetDB.

### Install the `bolt_shim` module in a PE environment

Bolt uses a task to execute commands, upload files, and run scripts over
orchestrator. To install this task, install the [`puppetlabs-bolt_shim`
module](https://forge.puppet.com/puppetlabs/bolt_shim) from the Forge. Install
the code in the same environment as the other tasks you want to run.

In addition to the `bolt_shim` module, any task or module content you want to
execute over Puppet Communications Protocol (PCP) must be present in the PE
environment. For details about downloading and installing modules for Bolt, see
[Set up Bolt to download and install
modules](https://puppet.com/docs/bolt/latest/installing_tasks_from_the_forge.html#task-8928).
By allowing only content that is present in the PE environment to be executed
over PCP, you maintain role-based access control over the nodes you manage in
PE.

To enable the Bolt`apply` action, you must install the
[`puppetlabs-apply_helpers`
module](https://forge.puppet.com/puppetlabs/apply_helpers).

**Note:** Bolt over orchestrator can require a large amount of memory to convey
large messages, such as the plugins and catalogs sent by `apply`. You might need
to [increase the Java heap
size](https://puppet.com/docs/pe/latest/config_java_args.html#increase-the-java-heap-size-for-pe-java-services)
for orchestration services.

### Assign task permissions to a user role

> **CAUTION:** Tasks executed with the `bolt_shim` module allow users
  to run any command as root on the nodes. Use the module at
  your own risk.

1.  In the console, click **Access control** > **User roles**.

2.  From the list of user roles, click the role you want to have task
    permissions.

3.  On the **Permissions** tab, in the **Type** box, select **Tasks**.

4.  For **Permission**, select **Run tasks**, and select **All** from the
    **Instance** drop-down list.

5.  Click **Add permission**, and commit the change.


### Specify and configure the PCP transport

Bolt runs tasks through the orchestrator when a target uses the `pcp` transport.
You can configure Bolt to connect to orchestrator in the `config` section of
your inventory file, or in the `inventory-config` section of your
`bolt-defaults.yaml` file. This configuration is not shared with [`puppet
task`](running_tasks_from_the_command_line.dita). By default, Bolt uses the
production environment in PE when running tasks.

For example, your inventory file might look something
like this:
```yaml
groups: 
  - name: linux    
    targets:
      - nix0.example.com
  - name: windows  
    targets:
      - win0.example.com
config: 
  transport: pcp
  pcp:
    cacert: "certs/cert.pem"
    service-url: "https://primary.example.com:8143"
    token-file: "tokens/token"
```

If you want to connect to multiple PE instances, create groups for each instance
and configure the `pcp` transport for each group.

For more information on configuration options for the `pcp` transport, see
[Transport configuration
options](https://puppet.com/docs/bolt/latest/bolt_transports_reference.html#pcp).

### Configure Bolt to connect to PuppetDB

Bolt can authenticate with PuppetDB through an SSL client certificate or a PE
RBAC token. For more information see the Bolt docs for [Connecting Bolt to
PuppetDB](https://puppet.com/docs/bolt/latest/bolt_connect_puppetdb.html).

```yaml
puppetdb:
  server_urls: ["https://expensive-tower.delivery.puppetlabs.net:8081", "https://amber-publisher.delivery.puppetlabs.net:8081"]
  cacert: /tmp/ca.pem
  token: ~/.puppetlabs/token
```

## Running tasks

In order to run tasks on nodes connected to your PE instance, each task must be
installed on the PE primary. To view tasks or plans installed on the PE primary's
production environment, run `puppet task show` or `puppet plan show`
respectively. To specify an environment other than production, use the
`--environment` flag. For example, `puppet task show --environment test`.

## Limitations

Some PCP functionality, such as running scripts, does not work if your
`/tmp` directory is mounted with `noexec`.
