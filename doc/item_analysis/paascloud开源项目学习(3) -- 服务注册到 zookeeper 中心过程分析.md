# 1 前言
- github 开源项目–paascloud-master：https://github.com/paascloud/paascloud-master
- paascloud-master 可靠消息设计文档：https://github.com/paascloud/paascloud-master/wiki/可靠消息

> 文档备份地址：https://blog.csdn.net/liu_zhaoming/article/details/79603036

# 2 可靠消息服务
在博客《paascloud开源项目学习(1) – 用户邮箱注册可靠消息服务流程》阐述的一个业务流程中，说明了本项目主要是基于 RocketMQ 的可靠消息服务 解决分布式事务。

## 2.1 zookeeper
仔细研读上面可靠消息设计文档，设计思想即原文：

> 因为项目采用的是 `rocketmq`，一个 `topic` 对应一个生产者，而可靠消息采用的是中间件负责发送消息，
> 又不能采用中间件的生产者为所有上游系统发送消息，这里引入了 `zookeeper` 做注册中心，
> 所以依赖可靠消息的服务，在启动项目的时候会像中间件去注册生产者，而中间件的 `watch 机制`会及时的更新生产者和消费者状态，
> 而中间件会为使用中间件的系统提供 `sdk`，使用者无需关注实现，只需要引入中间件的 `sdk` 和对应的注解即可完成可靠消息的发送和消费。

## 2.1.2 功能
1. 使用在可靠消息服务中，充当可靠消息服务的注册中心；
1. 分布式ID协调者 角色。
根据博客 paascloud开源项目学习(2) – centos7 下安装 SpringCloud 环境 搭建好环境，运行项目后查看 `zk` 后，可以清楚看到上面两个功能的作用。

图片：post_3_2.1.2_1.jpg

> 当某个服务启动时，该服务如何以生产者或消费者的身份注册到 `zookeeper` 注册中心，以便后期执行业务时生产消息或消费消息？

## 2.2 代码流程
我们以服务 `paascloud-provider-uac` 启动为例，其他服务启动时都会执行下面流程！

### 2.2.1 ZookeeperInitRunner.java
初始化启动类。

在用户权限服务 `paascloud-provider-uac` 启动过程中，实现 `CommandLineRunner` 的类 `ZookeeperInitRunner` 执行 `run()` ，注册…。

> 其他服务启动都会执行该类，根据各自服务的配置文件完成不同的初始化过程。

1. 代码：
```java
@Component
@Order
@Slf4j
public class ZookeeperInitRunner implements CommandLineRunner {
	@Resource
	private PaascloudProperties paascloudProperties;
	@Value("${spring.application.name}")
	private String applicationName;

	/**
	 * Run.
	 */
	@Override
	public void run(String... args) throws Exception {
		String hostAddress = InetAddress.getLocalHost().getHostAddress();
		log.info("###ZookeeperInitRunner，init. HostAddress={}, applicationName={}", hostAddress, applicationName);
		// 1. 重点代码，进入下面代码
		RegistryCenterFactory.startup(paascloudProperties, hostAddress, applicationName);
		log.info("###ZookeeperInitRunner，finish<<<<<<<<<<<<<");
	}

}
```
2. 控制台
> 每个服务（生产者、消费者服务）的配置参数都是不同的！

```log
[paascloud-provider-uac,,,,] 17044 --- [main] c.p.core.config.ZookeeperInitRunner: ###ZookeeperInitRunner，init. HostAddress=10.0.75.1, applicationName=paascloud-provider-uac
```

### 2.2.2 RegistryCenterFactory.java
注册中心工厂。
1. 代码：
```java
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class RegistryCenterFactory {

	private static final ConcurrentHashMap<HashCode, CoordinatorRegistryCenter> REG_CENTER_REGISTRY = new ConcurrentHashMap<>();

	/**
	 * 创建注册中心.
	 *
	 * @param zookeeperProperties the zookeeper properties
	 *
	 * @return 注册中心对象 coordinator registry center
	 */
	 // 下面的 1 执行该类。
	public static CoordinatorRegistryCenter createCoordinatorRegistryCenter(ZookeeperProperties zookeeperProperties) {
		Hasher hasher = Hashing.md5().newHasher().putString(zookeeperProperties.getZkAddressList(), Charsets.UTF_8);
		HashCode hashCode = hasher.hash();
		CoordinatorRegistryCenter result = REG_CENTER_REGISTRY.get(hashCode);
		if (null != result) {
			return result;
		}
		result = new ZookeeperRegistryCenter(zookeeperProperties);
		result.init();
		REG_CENTER_REGISTRY.put(hashCode, result);
		return result;
	}

	/**
	 * Startup.
	 *
	 * @param paascloudProperties the paascloud properties
	 * @param host                the host
	 * @param app                 the app
	 */
	public static void startup(PaascloudProperties paascloudProperties, String host, String app) {
		// 1. 初始化用于协调分布式服务的注册中心
		CoordinatorRegistryCenter coordinatorRegistryCenter = createCoordinatorRegistryCenter(paascloudProperties.getZk());
		RegisterDto dto = new RegisterDto(app, host, coordinatorRegistryCenter);
		// 2. 生成分布式ID
		Long serviceId = new IncrementIdGenerator(dto).nextId();
		IncrementIdGenerator.setServiceId(serviceId);
		// 3. 当前启动服务注册到 zookeeper 中心（即创建节点数据）
		registerMq(paascloudProperties, host, app);
	}
	
	/**
	 * 当前服务注册为生产者消费者到 zookeeper 中心
	 * @return void
	 */
	private static void registerMq(PaascloudProperties paascloudProperties, String host, String app) {
		CoordinatorRegistryCenter coordinatorRegistryCenter = createCoordinatorRegistryCenter(paascloudProperties.getZk());
		AliyunProperties.RocketMqProperties rocketMq = paascloudProperties.getAliyun().getRocketMq();
		String consumerGroup = rocketMq.isReliableMessageConsumer() ? rocketMq.getConsumerGroup() : null;
		String namesrvAddr = rocketMq.getNamesrvAddr();
		String producerGroup = rocketMq.isReliableMessageProducer() ? rocketMq.getProducerGroup() : null;
		coordinatorRegistryCenter.registerMq(app, host, producerGroup, consumerGroup, namesrvAddr);
	}
}
```

### 2.2.3 ZookeeperRegistryCenter.java
主要作用：

1. 初始化注册到中心的服务的配置类：`ZookeeperProperties.java`；
2. 生成 `zookeeper` 操作客户端类：`CuratorFramework`；
```java
/**
 * 基于 Zookeeper 的注册中心
 * 生成 zookeeper 客户端操作类 CuratorFramework
 *
 * @author zhangliang
 */
@Slf4j
public final class ZookeeperRegistryCenter implements CoordinatorRegistryCenter {
	@Getter(AccessLevel.PROTECTED)
	private ZookeeperProperties zkConfig;

	private final Map<String, TreeCache> caches = new HashMap<>();

	/** zookeeper操作客户端 */
	@Getter
	private CuratorFramework client;
	/** DistributedAtomicInteger：Curator框架分布式场景的分布式计数器 */
	@Getter
	private DistributedAtomicInteger distributedAtomicInteger;

	/**
	 * Instantiates a new Zookeeper registry center.
	 *
	 * @param zkConfig the zk config
	 */
	public ZookeeperRegistryCenter(final ZookeeperProperties zkConfig) {
		this.zkConfig = zkConfig;
	}

	/**
	 * Init.
	 */
	@Override
	public void init() {
		log.debug("Elastic job: zookeeper registry center init, server lists is: {}.", zkConfig.getZkAddressList());

		// Curator 建造者模式创建zookeeper客户端 <https://www.jianshu.com/p/70151fc0ef5d>
		CuratorFrameworkFactory.Builder builder = CuratorFrameworkFactory.builder()
				// 参数1：connectString zookeeper服务器列表（服务器地址及端口号，多个zookeeper服务器地址以 "," 分隔
				.connectString(zkConfig.getZkAddressList())
				// 参数2：retryPolicy 重试策略（一共四种，可以自行实现RetryPolicy接口）
				// 分别为：ExponentialBackoffRetry（重试指定的次数, 且每一次重试之间停顿的时间逐渐增加）
				.retryPolicy(new ExponentialBackoffRetry(zkConfig.getBaseSleepTimeMilliseconds(), zkConfig.getMaxRetries(), zkConfig.getMaxSleepTimeMilliseconds()));
		if (0 != zkConfig.getSessionTimeoutMilliseconds()) {
			// 参数3：sessionTimeoutMs 会话超时时间，默认60000ms
			builder.sessionTimeoutMs(zkConfig.getSessionTimeoutMilliseconds());
		}
		if (0 != zkConfig.getConnectionTimeoutMilliseconds()) {
			// 参数4：connectionTimeoutMs 连接创建超时时间，默认15000ms
			builder.connectionTimeoutMs(zkConfig.getConnectionTimeoutMilliseconds());
		}
		// 5. 连接Zookeeper的权限令牌
		if (!Strings.isNullOrEmpty(zkConfig.getDigest())) {
			builder.authorization("digest", zkConfig.getDigest().getBytes(Charsets.UTF_8))
					.aclProvider(new ACLProvider() {

						@Override
						public List<ACL> getDefaultAcl() {
							return ZooDefs.Ids.CREATOR_ALL_ACL;
						}

						@Override
						public List<ACL> getAclForPath(final String path) {
							return ZooDefs.Ids.CREATOR_ALL_ACL;
						}
					});
		}
		client = builder.build();
		// 启动zookeeper客户端
		client.start();
		try {
			if (!client.blockUntilConnected(zkConfig.getMaxSleepTimeMilliseconds() * zkConfig.getMaxRetries(), TimeUnit.MILLISECONDS)) {
				client.close();
				throw new KeeperException.OperationTimeoutException();
			}

			//CHECKSTYLE:OFF
		} catch (final Exception ex) {
			//CHECKSTYLE:ON
			RegExceptionHandler.handleException(ex);
		}
	}

	/**
	 * Close.
	 */
	@Override
	public void close() {
		for (Entry<String, TreeCache> each : caches.entrySet()) {
			each.getValue().close();
		}
		waitForCacheClose();
		CloseableUtils.closeQuietly(client);
	}

	/**
	 * 等待500ms, cache先关闭再关闭client, 否则会抛异常
	 * 因为异步处理, 可能会导致client先关闭而cache还未关闭结束.
	 * 等待Curator新版本解决这个bug.
	 * BUG地址：https://issues.apache.org/jira/browse/CURATOR-157
	 */
	private void waitForCacheClose() {
		try {
			Thread.sleep(500L);
		} catch (final InterruptedException ex) {
			Thread.currentThread().interrupt();
		}
	}
	// 省略其他...
}
```

### 2.2.4 IncrementIdGenerator.java
部署在不同机器的相同服务或不同服务注册到 `zookeeper` 中心的唯一分布式 ID。
1. 代码
```java
/**
 * FrameworkID 的保存器.（整个项目框架不同服务注册在zookeeper中心的唯一ID）
 *
 * @author gaohongtao
 */
public class IncrementIdGenerator implements IdGenerator {

	private static Long serviceId = null;
	private final RegisterDto registerDto;

	/**
	 * Instantiates a new Increment id generator.
	 * （实例化一个新的id自增生成器）
	 * @param registerDto the register dto
	 */
	public IncrementIdGenerator(RegisterDto registerDto) {
		this.registerDto = registerDto;
	}

	/**
	 * Next id long.
	 *
	 * @return the long
	 */
	@Override
	public Long nextId() {
		String app = this.registerDto.getApp();
		String host = this.registerDto.getHost();
		CoordinatorRegistryCenter regCenter = this.registerDto.getCoordinatorRegistryCenter();
		// 比如如果此时 uac 服务，path="/paascloud/registry/id/paascloud-provider-uac/10.0.75.1"
		String path = GlobalConstant.ZK_REGISTRY_ID_ROOT_PATH + GlobalConstant.Symbol.SLASH + app + GlobalConstant.Symbol.SLASH + host;
		if (regCenter.isExisted(path)) {
			// 如果 zookeeper 集群中已经有该节点，表示已经为当前的host上部署的该app分配的编号（应对某个服务重启之后编号不变的问题），直接获取该id，而无需生成
			return Long.valueOf(regCenter.getDirectly(GlobalConstant.ZK_REGISTRY_ID_ROOT_PATH + GlobalConstant.Symbol.SLASH + app + GlobalConstant.Symbol.SLASH + host));
		} else {
			// 1. 节点不存在，那么需要生成id，利用zk节点的版本号每写一次就自增的机制来实现
			// 对应的 zk 路径path 就是：/paascloud/seq						regCenter.increment(GlobalConstant.ZK_REGISTRY_SEQ, new RetryNTimes(2000, 3));
			// 生成id
			Integer id = regCenter.getAtomicValue(GlobalConstant.ZK_REGISTRY_SEQ, new RetryNTimes(2000, 3)).postValue();
			// 将数据写入节点
			regCenter.persist(path);
			regCenter.persist(path, String.valueOf(id));
			return Long.valueOf(id);
		}
	}

	/**
	 * Gets service id.
	 *
	 * @return the service id
	 */
	public static Long getServiceId() {
		return serviceId;
	}

	/**
	 * Sets service id.
	 *
	 * @param serviceId the service id
	 */
	public static void setServiceId(Long serviceId) {
		IncrementIdGenerator.serviceId = serviceId;
	}
}
```
2. 上面代码 `1` ，利用 `zk` 节点版本号来生成注册服务ID，指的是 `zk` 的 `/paascloud/seq` 节点的版本号！如果该启动的服务在 `zk` 中不存在，版本号就会自增。
```java
@Override
public void increment(String path, RetryNTimes retryNTimes) {
	try {
		distributedAtomicInteger = new DistributedAtomicInteger(client, path, retryNTimes);
		distributedAtomicInteger.increment();
	} catch (Exception e) {
		log.error("increment={}", e.getMessage(), e);
	}
}
```
3. 显示效果

图片：post_3_2.2.4_1.jpg/post_3_2.2.4_2.jpg

### 2.2.5 服务注册为生产者 OR 消费者
当前服务注册到 `zookeeper` 中心为生产者或消费者或两者都有。
> 重新回到目录 `2.2.2` 执行代码中的 `第 3 步`。

1. RegistryCenterFactory.java 代码：

图片：post_3_2.2.5_1.jpg

2. ZookeeperRegistryCenter.java 代码：
```java
/**
 * Register mq to zookeeper center.
 *
 * @param app           the app
 * @param host          the host
 * @param producerGroup the producer group
 * @param consumerGroup the consumer group
 * @param namesrvAddr   the namesrv addr
 */
@Override
public void registerMq(final String app, final String host, final String producerGroup, final String consumerGroup, String namesrvAddr) {
	// 生产者 zookeeper 节点路径
	final String producerRootPath = GlobalConstant.ZK_REGISTRY_PRODUCER_ROOT_PATH + GlobalConstant.Symbol.SLASH + app;
	// 消费者 zookeeper 节点路径
	final String consumerRootPath = GlobalConstant.ZK_REGISTRY_CONSUMER_ROOT_PATH + GlobalConstant.Symbol.SLASH + app;
	ReliableMessageRegisterDto dto;
	// 1. 注册生产者
	if (StringUtils.isNotEmpty(producerGroup)) {
		dto = new ReliableMessageRegisterDto().setProducerGroup(producerGroup).setNamesrvAddr(namesrvAddr);
		String producerJson = JSON.toJSONString(dto);
		// 保存到 zookeeper 节点和数据
		this.persist(producerRootPath, producerJson);
		this.persistEphemeral(producerRootPath + GlobalConstant.Symbol.SLASH + host, DateUtil.now());
	}
	// 2. 注册消费者
	if (StringUtils.isNotEmpty(consumerGroup)) {
		dto = new ReliableMessageRegisterDto().setConsumerGroup(consumerGroup).setNamesrvAddr(namesrvAddr);
		String producerJson = JSON.toJSONString(dto);
		this.persist(consumerRootPath, producerJson);
		this.persistEphemeral(consumerRootPath + GlobalConstant.Symbol.SLASH + host, DateUtil.now());
	}

}
```
3. zookeeper 树形结构展示：
 图片：post_3_2.2.5_2.jpg