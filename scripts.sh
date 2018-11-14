#!/bin/bash
clear
echo "Removendo antigas instalações..."
apt-get remove docker docker-engine docker.io --purge >> stdout.txt 2>> stderr.txt

echo "Atualizando repositório..."
apt-get update >> stdout.txt 2>> stderr.txt && \

echo "Instalando dependências..."
apt-get install apt-transport-https ca-certificates curl software-properties-common -y >> stdout.txt 2>> stderr.txt && \

echo "Instalando chave pública do Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >> stdout.txt 2>> stderr.txt && \

echo "Atualizando repositório para instalação do docker..."
add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> stdout.txt 2>> stderr.txt && \
apt-get update >> stdout.txt 2>> stderr.txt && \

echo "Instalando docker..."
apt-get install docker-ce -y >> stdout.txt 2>> stderr.txt && \

echo "Instalando nginx..."
apt-get install nginx-full -y >> stdout.txt 2>> stderr.txt && \

echo "Configurando o sistema..."
for i in {1..3}; do
mkdir -p /www/app$i
echo "<h1>app$i</h1>" > /www/app$i/index.html
echo "127.0.0.1 app$i.dexter.com.br" >> /etc/hosts
docker run -tid --name app$i --hostname app$i -p 1000$i:80 -v /www/app$i:/usr/local/apache2/htdocs/ httpd:2.4
cat << EOF > /etc/nginx/conf.d/app$i.conf
server {
	listen 80;
	server_name app$i.dexter.com.br;

	location / {
		proxy_pass http://localhost:1000$i;
	}
}
EOF
done

echo "Reiniciando o nginx..."
systemctl restart nginx
