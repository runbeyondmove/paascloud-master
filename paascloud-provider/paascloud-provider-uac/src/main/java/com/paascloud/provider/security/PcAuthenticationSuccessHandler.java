package com.paascloud.provider.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.paascloud.core.utils.RequestUtil;
import com.paascloud.provider.service.UacUserService;
import com.paascloud.security.core.SecurityUser;
import com.paascloud.wrapper.WrapMapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.MapUtils;
import org.apache.commons.lang.StringUtils;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.common.exceptions.UnapprovedClientAuthenticationException;
import org.springframework.security.oauth2.provider.*;
import org.springframework.security.oauth2.provider.token.AuthorizationServerTokenServices;
import org.springframework.security.web.authentication.SavedRequestAwareAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;


/**
 * APP环境下认证成功处理器.
 *
 * @author paascloud.net@gmail.com
 */
@Component("pcAuthenticationSuccessHandler")
@Slf4j
public class PcAuthenticationSuccessHandler extends SavedRequestAwareAuthenticationSuccessHandler {

	@Resource
	private ObjectMapper objectMapper;
	@Resource
	private ClientDetailsService clientDetailsService;
	@Resource
	private UacUserService uacUserService;

	//接口里定义了 OAuth 2.0 令牌的操作方法
	@Resource
	private AuthorizationServerTokenServices authorizationServerTokenServices;

	private static final String BEARER_TOKEN_TYPE = "Basic ";

	/**
	 * @param request
	 * @param response
	 * @param authentication  封装了所有的认证信息
	 * @throws IOException
	 * @throws ServletException
	 */
	@Override
	public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
	                                    Authentication authentication) throws IOException, ServletException {

		logger.info("登录成功");
        // 这个请求与gateway项目中的过滤器相关
		String header = request.getHeader(HttpHeaders.AUTHORIZATION);
		if (header == null || !header.startsWith(BEARER_TOKEN_TYPE)) {
			throw new UnapprovedClientAuthenticationException("请求头中无client信息");
		}

		String[] tokens = RequestUtil.extractAndDecodeHeader(header);
		assert tokens.length == 2;

		String clientId = tokens[0];
		String clientSecret = tokens[1];

		// 加载客户端信息
		ClientDetails clientDetails = clientDetailsService.loadClientByClientId(clientId);
		if (clientDetails == null) {
			throw new UnapprovedClientAuthenticationException("clientId对应的配置信息不存在:" + clientId);
		} else if (!StringUtils.equals(clientDetails.getClientSecret(), clientSecret)) {
			throw new UnapprovedClientAuthenticationException("clientSecret不匹配:" + clientId);
		}
		// 创建OAuth2AccessToken
		TokenRequest tokenRequest = new TokenRequest(MapUtils.EMPTY_MAP, clientId, clientDetails.getScope(), "custom");
		OAuth2Request oAuth2Request = tokenRequest.createOAuth2Request(clientDetails);
		OAuth2Authentication oAuth2Authentication = new OAuth2Authentication(oAuth2Request, authentication);
		OAuth2AccessToken token = authorizationServerTokenServices.createAccessToken(oAuth2Authentication);

		SecurityUser principal = (SecurityUser) authentication.getPrincipal();
		uacUserService.handlerLoginData(token, principal, request);

		log.info("用户【 {} 】记录登录日志", principal.getUsername());

		// 认证成功,把token写出
		response.setContentType("application/json;charset=UTF-8");
		response.getWriter().write((objectMapper.writeValueAsString(WrapMapper.ok(token))));

		// 把本类实现父类改成 AuthenticationSuccessHandler 的子类 SavedRequestAwareAuthenticationSuccessHandler
		// 之前说spring默认成功是跳转到登录前的url地址
		// 就是使用的这个类来处理的
		//super.onAuthenticationSuccess(request, response, authentication);
	}

}
