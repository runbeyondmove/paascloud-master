/*
 * Copyright (c) 2018. paascloud.net All Rights Reserved.
 * 项目名称：paascloud快速搭建企业级分布式微服务平台
 * 类名称：ResourceServerConfig.java
 * 创建人：刘兆明
 * 联系方式：paascloud.net@gmail.com
 * 开源地址: https://github.com/paascloud
 * 博客地址: http://blog.paascloud.net
 * 项目官网: http://paascloud.net
 */

package com.paascloud.provider.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.config.annotation.web.configuration.EnableResourceServer;
import org.springframework.security.oauth2.config.annotation.web.configuration.ResourceServerConfigurerAdapter;

import javax.servlet.http.HttpServletResponse;

/**
 * The class Resource server config.
 *
 * @author paascloud.net @gmail.com
 *
 * ResourceServerConfigurerAdapter 用于保护 OAuth2 要开放的资源，
 * 同时主要作用于client端以及token的认证(Bearer Auth)，由于后面 OAuth2 服务端后续还需要提供用户信息，
 * 所以也是一个 Resource Server，默认拦截了所有的请求，也可以通过重新方法方式自定义自己想要拦截的资源 URL 地址。
 *
 */
@Configuration
@EnableResourceServer //配置资源服务器
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {
	@Override
	public void configure(HttpSecurity http) throws Exception {
		http
				.headers().frameOptions().disable()
				.and()
				.csrf().disable() //关闭csrf
				.exceptionHandling() //允许配置错误处理
				.authenticationEntryPoint((request, response, authException) -> response.sendError(HttpServletResponse.SC_UNAUTHORIZED))
				.and()
				.authorizeRequests() //允许基于使用HttpServletRequest限制访问
				.antMatchers("/pay/alipayCallback", "/druid/**", "/swagger-ui.html", "/swagger-resources/**", "/v2/api-docs", "/api/applications")
				.permitAll() // 允许任何用户访问
				.anyRequest().authenticated();//其他请求用户认证后可以访问
	}
}
