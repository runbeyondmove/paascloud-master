package com.paascloud.security.core.validate.code;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.config.annotation.SecurityConfigurerAdapter;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.DefaultSecurityFilterChain;
import org.springframework.security.web.authentication.preauth.AbstractPreAuthenticatedProcessingFilter;
import org.springframework.stereotype.Component;

import javax.servlet.Filter;

/**
 * 校验码相关安全配置
 *
 * @author paascloud.net@gmail.com
 */
@Component("validateCodeSecurityConfig")
public class ValidateCodeSecurityConfig extends SecurityConfigurerAdapter<DefaultSecurityFilterChain, HttpSecurity> {
	@Autowired
	private Filter validateCodeFilter;

	/**
	 * Configure.
	 *
	 * @param http the http
	 */
	@Override
	public void configure(HttpSecurity http) {
		// 在认证流程中加入图像验证码校验：查看Spring Security的源码，可以发现只要把过滤器添加到spring现有的过滤器链上就可以了
		// 1. 编写验证码过滤器
		// 2. 放在UsernamePasswordAuthenticationFilter过滤器之前，
        // 因为Spring Security的过滤器链最前面的是UsernamePasswordAuthenticationFilter
		http.addFilterBefore(validateCodeFilter, AbstractPreAuthenticatedProcessingFilter.class);
	}

}
