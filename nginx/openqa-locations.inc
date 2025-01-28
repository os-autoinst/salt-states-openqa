root /usr/share/openqa/public;

client_max_body_size 0;

# The "client_body_buffer_size" value should usually be larger
# than the UPLOAD_CHUNK_SIZE used by openQA workers, so there is
# no excessive buffering to disk
client_body_buffer_size 2m;

# Default is exact which would need an exact match of Last-Modified
if_modified_since before;

# Optional faster assets downloads for large deployments
# note: There is a distinct location for repo/iso assets to allow unauthorized access
# despite generally requiring authorization. The unauthorized access is required by
# many tests and authorization is also not necassary as those assets do not contain
# embargoed data.
location ~ ^/assets/((repo|iso)(/.*)?)$ {
    alias /var/lib/openqa/share/factory/$1;
    include conf.d/openqa-asset-config.inc;
}
location /assets {
    alias /var/lib/openqa/share/factory/;
    include conf.d/openqa-asset-config.inc;
    auth_request /api/v1/auth;
}

# Optional to make use of auth_request to require authentication for asset downloads
location /api/v1/auth {
    internal;
    proxy_pass http://webui;
    tcp_nodelay        on;
    proxy_read_timeout 900;
    proxy_send_timeout 900;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header Host $host;
    proxy_set_header X-Original-URI $request_uri;
    proxy_set_header X-Forwarded-Host $host:$server_port;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Optional faster image downloads for large deployments
location /image {
    alias /var/lib/openqa/images/;
    tcp_nopush         on;
    sendfile           on;
    sendfile_max_chunk 1m;
}

location /api/v1/ws/ {
    proxy_pass http://websocket;
    proxy_http_version 1.1;
    proxy_read_timeout 3600;
    proxy_send_timeout 3600;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}

location /liveviewhandler/ {
    proxy_pass http://livehandler;
    proxy_http_version 1.1;
    proxy_read_timeout 3600;
    proxy_send_timeout 3600;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}

location / {
    proxy_pass "http://webui";
    tcp_nodelay        on;
    proxy_read_timeout 900;
    proxy_send_timeout 900;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host:$server_port;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    # Increased buffer sizes for large API requests
    proxy_buffer_size 16k;
    proxy_buffers 32 16k;
    proxy_busy_buffers_size 32k;
}
