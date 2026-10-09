#!/bin/bash  

GREEN="\033[32m" 
RED="\033[31m" 
NC="\033[0m" 

function print_banner {  
  clear  
  echo -e "${GREEN}"  
  echo "============================================="  
  echo "         ATUALIZAÇÃO PLW CLUB VIP            "  
  echo "============================================="  
  echo -e "${NC}"  
  printf "${GREEN}"     
  printf "██████╗░██╗░░░░░░██╗░░░░░░░██╗\n";  
  printf "██╔══██╗██║░░░░░░██║░░██╗░░██║\n";  
  printf "██████╔╝██║░░░░░░╚██╗████╗██╔╝\n";  
  printf "██╔═══╝░██║░░░░░░░████╔═████║░\n";  
  printf "██║░░░░░███████╗░░╚██╔╝░╚██╔╝░\n";  
  printf "╚═╝░░░░░╚══════╝░░░╚═╝░░░╚═╝░░\n";  
  printf "${NC}"  
}  

function get_incremented_folder_name {  
  base_name="$1-old"  
  increment=1  
  new_folder_name="$base_name"  
  while [ -d "$new_folder_name" ]; do  
    new_folder_name="${base_name}-${increment}"  
    increment=$((increment + 1))  
  done  
  echo "$new_folder_name"  
}  

print_banner  
echo -e "${GREEN}AVISO IMPORTANTE: Antes de prosseguir, faça um backup e snapshot da sua máquina (VPS).${NC}"  
read -p "Deseja continuar? [Y/N]: " choice  
if [[ "$choice" != "Y" && "$choice" != "y" ]]; then  
  echo -e "${GREEN}Operação cancelada. Por favor, faça um backup antes de prosseguir.${NC}"  
  exit 1  
fi  

print_banner  
echo -e "${GREEN}Parando todas as tarefas do PM2...${NC}"  
sudo su deploy -c "pm2 stop all"  
sudo su deploy -c "exit"  

print_banner  
echo -e "${GREEN}Digite o caminho do diretório de deploy (ex: /home/deploy):${NC}"  
read deploy_path  
if [ ! -d "$deploy_path" ]; then  
  echo -e "${RED}Caminho $deploy_path não existe. Operação cancelada.${NC}"  
  exit 1  
fi  
cd "$deploy_path" || { echo -e "${RED}Falha ao acessar o caminho $deploy_path. Operação cancelada.${NC}"; exit 1; }  

print_banner  
echo -e "${GREEN}Digite o nome da pasta que deseja renomear:${NC}"  
read old_folder_name  
if [ ! -d "$old_folder_name" ]; then  
  echo -e "${RED}A pasta $old_folder_name não existe. Operação cancelada.${NC}"  
  exit 1  
fi  

print_banner  
new_old_folder_name=$(get_incremented_folder_name "$old_folder_name")  
mv "$old_folder_name" "$new_old_folder_name"  

echo -e "${GREEN}Digite o novo nome para a pasta:${NC}"  
read new_folder_name  
github_user="plwdesign"  
echo -e "${GREEN}Digite a senha do GitHub para o usuário ${github_user} (a senha ficará invisível):${NC}"  
read -s github_password  
git clone https://${github_user}:${github_password}@github.com/plwdesign/vipclub.git "$new_folder_name"  

print_banner  
cp "$new_old_folder_name/backend/.env" "$new_folder_name/backend/.env"  
cp "$new_old_folder_name/frontend/.env" "$new_folder_name/frontend/.env"  
cp "$new_old_folder_name/frontend/server.js" "$new_folder_name/frontend/server.js"  

print_banner  
echo -e "${GREEN}Limpando diretório do backend...${NC}"  
cd "$deploy_path/$new_folder_name/backend" || { echo -e "${RED}Falha ao acessar o diretório do backend. Operação cancelada.${NC}"; exit 1; }  
rm -rf node_modules package-lock.json dist  
echo -e "${GREEN}Rodando comandos no backend...${NC}"  
npm install  
npm run build  
npx sequelize db:migrate  

print_banner  
echo -e "${GREEN}Verificando e criando pasta backups no backend...${NC}"  
if [ ! -d "$deploy_path/$new_folder_name/backend/backups" ]; then  
  echo -e "${GREEN}Pasta backups não existe. Criando...${NC}"  
  mkdir -p "$deploy_path/$new_folder_name/backend/backups"  
  chmod 775 "$deploy_path/$new_folder_name/backend/backups"  
  chown deploy:deploy "$deploy_path/$new_folder_name/backend/backups"  
  echo -e "${GREEN}Pasta backups criada com sucesso!${NC}"  
else  
  echo -e "${GREEN}Pasta backups já existe. Ajustando permissões...${NC}"  
  chmod 775 "$deploy_path/$new_folder_name/backend/backups"  
  chown deploy:deploy "$deploy_path/$new_folder_name/backend/backups"  
  echo -e "${GREEN}Permissões ajustadas!${NC}"  
fi  

print_banner  
echo -e "${GREEN}Rodando comandos no frontend...${NC}"  
cd "$deploy_path/$new_folder_name/frontend" || { echo -e "${RED}Falha ao acessar o diretório do frontend. Operação cancelada.${NC}"; exit 1; }  
npm install --force
npm run build  

print_banner  
echo -e "${GREEN}Abrindo o package.json no frontend para editar...${NC}"  
nano "$deploy_path/$new_folder_name/frontend/package.json"  

print_banner  
echo -e "${GREEN}Abrindo o index.html no frontend/public para editar...${NC}"  
nano "$deploy_path/$new_folder_name/frontend/public/index.html"  

print_banner  
echo -e "${GREEN}Rodando npm install e npm run build novamente no frontend...${NC}"  
npm install --force 
npm run build  

print_banner  
echo -e "${GREEN}Reiniciando o PM2...${NC}"  
sudo su deploy -c "pm2 restart all"  

print_banner  
echo -e "${RED}Mova a pasta 'public' para o novo diretório, se necessário.${NC}"  

print_banner  
echo -e "${GREEN}Script finalizado. Se aconteceu algum erro nos chame no suporte!${NC}"  
echo -e "${GREEN} npm install (No backend)  
npm run build (No backend)  
npx sequelize db:migrate (No backend)  

npm install --force (No frontend)  
npm run build (No frontend)  

sudo su deploy  
pm2 restart all ${NC}"  

echo -e "${GREEN}Sites e Contatos:${NC}"  
echo -e "${GREEN}Site: www.plwdesign.online${NC}"  
echo -e "${GREEN}Site: vip.plwdesign.online${NC}"  
echo -e "${GREEN}Suporte pelo site!${NC}"  