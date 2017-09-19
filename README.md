xdg-limit-traffict 是基于openresty的一个请求速率限制库，它基于lua-resty-limit-traffic库，配置十分简单。

安装
====

1.安装[openresty](https://openresty.org)

2.安装[lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic),下载后cp -r lib/resty/limit /usr/local/openresty/lualib/resty/

3.下载[xdg-limit-traffic](https://github.com/ganxiangdong/xdg-limit-traffic)，下载后 cp -r limit  /usr/local/openresty/lualib/



ngixn配置示例：
====
```
lua_shared_dict www.example.com 100m; #配置一个空间，名称和$limit_domain一致，不重复就行, 最后的空间，大小需要足够放置限流所需的键值，以IP为例：每个 $binary_remote_addr 大小不会超过 16K，算上 lua_shared_dict 的节点大小，总共不到 64 字节，100M 可以放约160万个键值对
server {
        listen       8012;
        server_name  localhost;

        #配置限速
        set $limit_shared_dict_name   'www.example.com';        #必须，设置lua_shared_dict的名称
        set $limit_white_ip   '^192\.168\..+';      #非必须,设置ip白名单正则表达式，符合白名单的ip请求将不受限制
        set $limit_white_uri   '/(css)|(js)|(images)';     #非必须,设置url白名单，符合白名单的URL请求将不受限制
        set $limit_global   '1000,200';         #非必须,设置全局的速率控制，如您的服务器最多只能承受2000的并发，则这里可以配置成"2000,1000",第二个参数是延迟到下一个周期的请求个数,这里表示1秒允许2000个请求，超过且小于1000个的请求放到下一秒，超过3000的直接返回503.
        set $limit_ip       '50,50';        #非必须,设置ip的速度控制
        set $limit_itentity '10,5';        #非必须,设置以某身分的key的速率，通常我们需要登陆成功的用户速率调大或调小，使用这个配置需要设置名为_identity的cookey。格式为：用户id_密钥。密钥的算法为md5(用户id + limit_identity_secret_key)
        set $limit_identity_secret_key "your secret key";       #非必须,如果配置了配置了limit_itentity，则此参数为必须
        set $limit_member_ip_relation "or";        #非必须,如果配置了配置了limit_itentity，则此参数为必须，identity和ip限制的关系，如果为or，则用户登陆后不受ip的速率限制
        access_by_lua_file '/usr/local/openresty/lualib/xdg-limit-traffic/limit/rate_access.lua';       # 必须，指定速率控制脚本

}

```






