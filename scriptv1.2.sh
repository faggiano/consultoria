#!/bin/bash
clear
echo "Olah, este script configura proxy reverso utilizando nginx para um numero de aplicacoes em containeres httpd"
echo "Por questao de seguranca e performance limitei a criacao para ateh 15 instancias"
read -p "Digite quantas instancias httpd\'s serao levantadas: " i
ii=$i
[[ $i =~ (^[1-9]$|^1[0-5]$) ]] || { clear ; echo Valor invalido ; exit 1 ; }
echo "Removendo antigas instalações..."
apt-get remove docker docker-engine docker.io --purge >> stdout.txt 2>> stderr.txt
{
echo "Atualizando repositório..."
apt-get update >> stdout.txt 2>> stderr.txt
} && {
echo "Instalando dependências..."
apt-get install apt-transport-https ca-certificates curl software-properties-common -y >> stdout.txt 2>> stderr.txt
} && {
echo "Instalando chave pública do Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >> stdout.txt 2>> stderr.txt
} && {
echo "Atualizando repositório para instalação do docker..."
add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> stdout.txt 2>> stderr.txt
apt-get update >> stdout.txt 2>> stderr.txt
} && {
echo "Instalando docker..."
	{
		apt-get install docker-ce -y || apt-get install docker -y
	}  >> stdout.txt 2>> stderr.txt
} && {
echo "Instalando nginx..."
apt-get install nginx-full -y >> stdout.txt 2>> stderr.txt
} && {
echo "Configurando o sistema..."
until (( $i == 0 )); do
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
((i--))
done
} && {
echo "Reiniciando o nginx..."
systemctl restart nginx
} && {
until (( $ii == 0 )); do
	echo "curl http://app$i.dexter.com.br"
	curl http://app$i.dexter.com.br
	((ii--))
done
} || {
tail stderr.txt
}
