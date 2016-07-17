vcl 4.0;
 
import std;
include "backends.vcl";
 
acl allow_purge_cache {
    "127.0.0.1";
    "10.0.0.0"/8;
    "172.0.0.0"/8;
}
 
sub vcl_recv {
    if (req.method == "PURGE") {
        if (!client.ip ~ allow_purge_cache) {
            return (synth(405, "Not Allowed."));
        }
         
        return (purge);
    }
     
    set req.backend_hint = web.backend();
     
    if (req.url ~ "\.(php|asp|aspx|jsp|do|ashx|shtml)($|\?)") {
        return (pass);
    }
     
    if (req.url ~ "\.(css|js|html|htm|bmp|png|gif|jpg|jpeg|ico|gz|tgz|bz2|tbz|zip|rar|mp3|mp4|ogg|swf|flv)($|\?)") {
        unset req.http.cookie;
        return (hash);
    }
     
    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }
     
    if (req.http.Cache-Control ~ "(?i)no-cache") {
        if (!(req.http.Via || req.http.User-Agent ~ "(?i)bot" || req.http.X-Purge)) {
            return (purge);
        }
    }
     
    if (req.method != "GET" && 
        req.method != "HEAD" && 
        req.method != "PUT" && 
        req.method != "POST" && 
        req.method != "TRACE" && 
        req.method != "OPTIONS" && 
        req.method != "PATCH" && 
        req.method != "DELETE") {        
        return (pipe);
    }
     
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
     
    if (req.http.Authorization) {
        return (pass);
    }
     
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(bmp|png|gif|jpg|jpeg|ico|gz|tgz|bz2|tbz|zip|rar|mp3|mp4|ogg|swf|flv)$") {
            unset req.http.Accept-Encoding;        
        } elseif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elseif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }
     
    if (req.http.Upgrade ~ "(?i)websocket") {
        return (pipe);
    }
     
    if (!std.healthy(req.backend_hint)) {
        unset req.http.Cookie;
    }
     
    if (req.http.x-pipe && req.restarts > 0) {
        unset req.http.x-pipe;
        return (pipe);
    }
     
    return (hash);
}
 
sub vcl_pipe {
    if (req.http.upgrade) {
        set bereq.http.upgrade = req.http.upgrade;
    }
     
    return (pipe);
}
 
sub vcl_pass {
    if (req.method == "PURGE") {
        return (synth(502, "PURGE on a passed object."));
    }
}
 
sub vcl_hash {
    hash_data(req.url);
     
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
     
    if (req.http.Cookie) {
        hash_data(req.http.Cookie);
    }
     
    if (req.http.Accept-Encoding ~ "gzip") {
        hash_data("gzip");
    } elseif (req.http.Accept-Encoding ~ "deflate") {
        hash_data("deflate");
    }
}
 
sub vcl_hit {
    if (req.method == "PURGE") {
        return (synth(200, "Purged."));
    }
     
    if (obj.ttl >= 0s) {
        return (deliver);
    }
     
    if (std.healthy(req.backend_hint)) {
        if (obj.ttl + 10s > 0s) {
            return (deliver);
        } else {
            return(fetch);
        }
    } else {
        if (obj.ttl + obj.grace > 0s) {
            return (deliver);
        } else {
            return (fetch);
        }
    }
     
    return (deliver);
}
 
sub vcl_miss {
    if (req.method == "PURGE") {
        return (synth(404, "Purged."));
    }
     
    return (fetch);
}
 
sub vcl_backend_response {
    set beresp.grace = 5m;
     
    set beresp.ttl = std.duration(regsub(beresp.http.Cache-Control, ".*s-maxage=([0-9]+).*", "\1") + "s", 0s);
    if (beresp.ttl > 0s) {
        unset beresp.http.Set-Cookie;
    }
     
    if (beresp.http.Set-Cookie) {
        set beresp.uncacheable = true;
        return (deliver);
    }
     
    if (beresp.http.Cache-Control && beresp.ttl > 0s) {
        set beresp.grace = 1m;
        unset beresp.http.Set-Cookie;
    }
     
    if (beresp.http.Content-Length ~ "[0-9]{8,}") {
        set bereq.http.x-pipe = "1";
        return (retry);
    }
     
    if (bereq.url ~ "\.(php|asp|aspx|jsp|do|ashx|shtml)($|\?)") {
        set beresp.uncacheable = true;
        return (deliver);
    }
     
    if (bereq.url ~ "\.(css|js|html|htm|bmp|png|gif|jpg|jpeg|ico|gz|tgz|bz2|tbz|zip|rar|mp3|mp4|ogg|swf|flv)($|\?)") {
        unset beresp.http.set-cookie;
    }
     
    if (bereq.url ~ "^[^?]*\.(mp[34]|rar|tar|tgz|gz|wav|zip|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av])(\?.*)?$") {
        unset beresp.http.set-cookie;
        set beresp.do_stream = true;
        set beresp.do_gzip = false;
    }
     
    if ((!beresp.http.Cache-Control && !beresp.http.Expires) || 
         beresp.http.Pragma ~ "no-cache" || 
         beresp.http.Cache-Control ~ "(no-cache|no-store|private)") {
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }
     
    if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary == "*") {
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }
     
    if (bereq.url ~ "\.(css|js|html|htm|bmp|png|gif|jpg|jpeg|ico)($|\?)") {
        set beresp.ttl = 180m;
    } elseif (bereq.url ~ "\.(gz|tgz|bz2|tbz|zip|rar|mp3|mp4|ogg|swf|flv)($|\?)") {
        set beresp.ttl = 30m;
    } else {
        set beresp.ttl = 60m;
    }
     
    return (deliver);
}
 
sub vcl_purge {
    if (req.method != "PURGE") {
        set req.http.X-Purge = "Yes";
        return (restart);
    }
}
 
sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT from " + req.http.host;
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS from " + req.http.host;
    }
     
    unset resp.http.X-Powered-By;
    unset resp.http.Server;
     
    unset resp.http.Via;
    unset resp.http.X-Varnish;
     
    unset resp.http.Age;
}
 
sub vcl_backend_error {
    if (beresp.status == 500 || 
        beresp.status == 501 || 
        beresp.status == 502 || 
        beresp.status == 503 || 
        beresp.status == 504) {
        return (retry);
    }
}
 
sub vcl_fini {
    return (ok);
}