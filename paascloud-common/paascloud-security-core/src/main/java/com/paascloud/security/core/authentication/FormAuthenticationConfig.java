package com.paascloud.security.core.authentication;

import com.paascloud.security.core.properties.SecurityConstants;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

/**
 * 表单登录配置
 *
 * @author paascloud.net @gmail.com
 */
@Component
public class FormAuthenticationConfig {

	/**
	 * The Pc authentication success handler.
	 */
	protected final AuthenticationSuccessHandler pcAuthenticationSuccessHandler;

	/**
	 * The Pc authentication failure handler.
	 */
	protected final AuthenticationFailureHandler pcAuthenticationFailureHandler;

	/**
	 * Instantiates a new Form authentication config.
	 *
	 * @param pcAuthenticationSuccessHandler the pc authentication success handler
	 * @param pcAuthenticationFailureHandler the pc authentication failure handler
	 */
	@Autowired
	public FormAuthenticationConfig(AuthenticationSuccessHandler pcAuthenticationSuccessHandler, AuthenticationFailureHandler pcAuthenticationFailureHandler) {
		this.pcAuthenticationSuccessHandler = pcAuthenticationSuccessHandler;
		this.pcAuthenticationFailureHandler = pcAuthenticationFailureHandler;
	}

	/**
	 * Configure.
	 *
	 * @param http the http
	 *
	 * @throws Exception the exception
	 */
	public void configure(HttpSecurity http) throws Exception {
		// 在v5+中，该配置（表单登录）应该是默认配置了
		// basic登录（也就是弹框登录的）应该是v5-的版本默认
		http.formLogin()
				// 自定义登录页面
				.loginPage(SecurityConstants.DEFAULT_UNAUTHENTICATION_URL)
				// 自定义登录请求路径，而UsernamePasswordAuthenticationFilter默认是处理/login路径的登录请求（无参构造函数里面）
				// 疑问：这个路径一定要真实存在吗？不存在行不行？
				// 不需要真实存在,因为这个是提供这两个特定过滤器框架特定的拦截点。只有提交到指定的拦截点,才会进入认证功能服务
				.loginProcessingUrl(SecurityConstants.DEFAULT_SIGN_IN_PROCESSING_URL_FORM)
				//security 默认的登录成功处理是跳转到需要授权之前访问的url；
				// 而在一些场景下：比如 前后分离，登录是通过ajax访问，没有办法处理301跳转； 而是登录成功则返回相关的数据即可；
				.successHandler(pcAuthenticationSuccessHandler)
				.failureHandler(pcAuthenticationFailureHandler);
	}

}
