启动报异常：
```
2019-04-02 22:54:00.951  INFO 5720 --- [82NdyzU0_eUhQ-3] o.s.a.r.l.SimpleMessageListenerContainer : Restarting Consumer@48e88a8e: tags=[{}], channel=null, acknowledgeMode=AUTO local queue size=0
2019-04-02 22:54:00.953  INFO 5720 --- [82NdyzU0_eUhQ-4] o.s.a.r.c.CachingConnectionFactory       : Attempting to connect to: [paascloud-mq-rabbit:5672]
2019-04-02 22:54:00.996 ERROR 5720 --- [.89.51.123:5672] c.r.c.impl.ForgivingExceptionHandler     : An unexpected connection driver error occured
java.net.SocketException: socket closed
	at java.net.SocketInputStream.socketRead0(Native Method)
	at java.net.SocketInputStream.socketRead(SocketInputStream.java:116)
	at java.net.SocketInputStream.read(SocketInputStream.java:170)
	at java.net.SocketInputStream.read(SocketInputStream.java:141)
	at java.io.BufferedInputStream.fill(BufferedInputStream.java:246)
	at java.io.BufferedInputStream.read(BufferedInputStream.java:265)
	at java.io.DataInputStream.readUnsignedByte(DataInputStream.java:288)
	at com.rabbitmq.client.impl.Frame.readFrom(Frame.java:91)
	at com.rabbitmq.client.impl.SocketFrameHandler.readFrame(SocketFrameHandler.java:164)
	at com.rabbitmq.client.impl.AMQConnection$MainLoop.run(AMQConnection.java:571)
	at java.lang.Thread.run(Thread.java:745)

```
rabbitmq连接发生错误

配置：
```properties
spring:
  rabbitmq:
    host: paascloud-mq-rabbit
    port: 5672
    username: paas
    password: paas@run
```

原因：如上配置没有为rabbitmq指定可以访问的virtual hosts，那就默认是/
但是paas用户上没有配置可以访问/的权限，所以连接不到

解决：
为pass用户指定virtual hosts为paas_virtual

并在配置上添加上`virtual-host: paas_virtual`，重启服务，一切正常