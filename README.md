# Warpstream on Tigris

![A blue cartoon tiger riding a canoe down a river of data with a happy orca breaching the water next to him](./.img/ty-stream.jpg)

[Warpstream](https://www.warpstream.com/) lets you store an unlimited amount of data in your message queues, but when you set it up with S3 or other object stores, you end up having to pay egress fees to read messages. Tigris is globally performant object storage without egress fees. When you combine the two, you get a bottomless durable message queue that lets you store however much you want without having to worry about where your data is.

Before we get started, let’s cover the moving parts:

- [**Apache Kafka**](https://kafka.apache.org/) is a durable message queue. In Kafka, Producers send Messages into Topics hosted by Brokers that are read by Consumers or Consumer Groups. Kafka is one of the most popular message queue programs. It’s deployed by 80% of Fortune 500 companies because it’s very fault-tolerant and its durability means that the Queues continue functioning even as Brokers go down. The main downside is that Kafka relies on local storage, meaning that your Kafka Brokers need to have lots of fast storage.
- [**Warpstream**](https://www.warpstream.com/) is like Kafka but it improves on it in one key way: Warpstream puts every Message in every Topic into objects in an S3-compatible object store. This means that the amount of data you hold in your queue isn’t limited by the amount of storage in each server running Warpstream. This also means you don’t need to set up all of Kafka’s dependencies (Zookeeper, the JVM, etc). Warpstream also ships an easy to use command line utility that helps you administrate your message queue and test functionality.
- [**Docker**](https://docker.com) is the universal package format for the Internet. Docker lets you put your application and all its dependencies into a container image so that it can’t conflict with anything else on the system.

Today we’re going to deploy a Warpstream Broker backed by Tigris into a Docker container so you can create your own bottomless durable message queue. This example will use [Docker compose](https://docs.docker.com/compose/), but it will help you understand how to create your own broker so you can deploy it anywhere.

## Prerequisites

Make sure you have the following installed on your computer:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or another similar app like [Podman Desktop](https://podman-desktop.io/).
- The [AWS CLI](https://aws.amazon.com/cli/).
- [Warpstream’s CLI](https://docs.warpstream.com/warpstream/reference/cli-reference).

You will need the following accounts:

- A Tigris account from [storage.new](https://storage.new).
- A Warpstream account from [console.warpstream.com](http://console.warpstream.com/login)

## Building a compose file

First, clone [tigrisdata-community/warpstream-tigris](https://github.com/tigrisdata-community/warpstream-tigris) to your laptop and open it in your favourite text editor. If you use [development containers](https://www.tigrisdata.com/blog/dev-containers-python/), tell your editor to open this repository in a development container to get up and running in a snap\!

Take a look at the `docker-compose.yaml` file in the root of the repository:

```yaml
services:
  warp:
    # Grab the latest copy of the warpstream agent for your computer
    image: public.ecr.aws/warpstream-labs/warpstream_agent:latest
    # Run warpstream in "playground" mode for testing
    command:
      - playground
      - -advertiseHostnameStrategy
      - custom
      - -advertiseHostnameCustom
      - warp
    environment:
      # this is a no-op as it will default on the custom advertised hostname defined above, but you can change this if you want to use a different hostname with Kafka
      - WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE=warp
    healthcheck:
      # Wait for the Agent to finish setting up the demo before marking it as healthy
      # to delay the diagnose-connection command from running for a few seconds.
      test: ["CMD", "sh", "-c", "sleep 10"]
      interval: 5s
      timeout: 15s
      retries: 5
```

Open a new terminal in your development container and make sure Warpstream is up and running:

```text
warpstream kcmd --bootstrap-host warp --type diagnose-connection
```

This should return output like the following:

```text
running diagnose-connection sub-command with bootstrap-host: warp and bootstrap-port: 9092


Broker Details
---------------
  warp:9092 (NodeID: 1547451680) [playground]
    ACCESSIBLE ✅


GroupCoordinator: warp:9092 (NodeID: 1547451680)
    ACCESSIBLE ✅
```

Excellent\! Create a new topic with `warpstream kcmd`:

```text
warpstream kcmd --bootstrap-host warp --type create-topic --topic hello
```

This should return output like the following:

```text
running create-topic sub-command with bootstrap-host: warp and bootstrap-port: 9092

created topic "hello" successfully, topic ID: MQAAAAAAAAAAAAAAAAAAAA==
```

Perfect\! Now let’s make it work with Tigris. Create a `.env` file in the root of the repository:

```sh
cp .env.example .env
code .env
```

Create a new bucket at [storage.new](https://storage.new) in the Standard access tier. Copy its name down into your notes. Create a new [access key](https://storage.new/accesskey) with Editor permissions for that bucket. Copy the environment details into your `.env` file:

```sh
## Tigris credentials
AWS_ACCESS_KEY_ID=tid_access_key_id
AWS_SECRET_ACCESS_KEY=tsec_secret_access_key
AWS_ENDPOINT_URL_S3=https://t3.storage.dev
AWS_ENDPOINT_URL_IAM=https://iam.storage.dev
AWS_REGION=auto
```

Then fill in your Warpstream secrets from the console, you need the following:

- Cluster ID from the virtual clusters list (begins with `vci_`)
- Bucket URL (explained below)
- Agent key from the agent keys page for that virtual cluster (begins with `aks_`)
- Cluster region from the admin panel (such as `us-east-1`)

If your bucket is named `xe-warpstream-demo`, your bucket URL should look like this:

```text
s3://xe-warpstream-demo?region=auto&endpoint=https://t3.storage.dev
```

Altogether, put these credentials in your `.env` file:

```sh
## Warpstream credentials
WARPSTREAM_AGENT_KEY=aks_agent_key
WARPSTREAM_BUCKET_URL='s3://xe-warpstream-demo?region=auto&endpoint=https://t3.storage.dev'
WARPSTREAM_DEFAULT_VIRTUAL_CLUSTER_ID=vci_cluster_id
WARPSTREAM_REGION=us-east-1
```

Edit your `docker-compose.yaml` file to load the `.env` file and start warpstream in agent mode:

```yaml
# docker-compose.yaml
services:
  warp:
    image: public.ecr.aws/warpstream-labs/warpstream_agent:latest
    command:
      - agent
    environment:
      WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE: warp
      WARPSTREAM_DISCOVERY_KAFKA_PORT_OVERRIDE: 9092
      WARPSTREAM_REQUIRE_AUTHENTICATION: "false"
    env_file:
      - .env
```

Then restart your development container with control/command shift-p “Dev Containers: Rebuild Container”. Test the health of your Broker:

```text
warpstream kcmd --bootstrap-host warp --type diagnose-connection
```

You should get output like this:

```text
running diagnose-connection sub-command with bootstrap-host: warp and bootstrap-port: 9092


Broker Details
---------------
  warp:9092 (NodeID: 1415344910) [warpstream-unset-az]
    ACCESSIBLE ✅


GroupCoordinator: warp:9092 (NodeID: 1415344910)
    ACCESSIBLE ✅
```

It’s working\! Create a topic and publish some messages:

```text
warpstream kcmd --bootstrap-host warp --type create-topic --topic hello
warpstream kcmd --bootstrap-host warp --type produce --topic hello --records "world,,world"
```

This should create the topic `hello` and two messages with `world` in them. You should get output like this:

```text
result: partition:0 offset:0 value:"world"
result: partition:0 offset:1 value:"world"
```

Now let’s read them back:

```text
warpstream kcmd --bootstrap-host warp --type fetch --topic hello --offset 0
```

You should get output like this:

```text
consuming topic:"hello" partition:0 offset:0
result: partition:0 offset:0 key:"hello" value:"world"
result: partition:0 offset:1 key:"hello" value:"world"
```

It works\! You’ve successfully put data into a queue and fetched it back from the queue. From here you can connect to your broker on host `warp` and port `9092`. All your data is securely backed by Tigris and you can access it from anywhere in the world.
