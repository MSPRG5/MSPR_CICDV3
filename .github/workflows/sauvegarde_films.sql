name: Industrialisation continue sur le serveur AWS (Tomcat)
on: push
jobs:
  build:
    name: Package AWS
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - run: |
          jar cvf Elyes.war *
    - name: copy file via ssh password
      uses: appleboy/scp-action@master
      with:
        host: ${{ secrets.HOST_DNS }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.EC2_SSH_KEY }}
        port: ${{ secrets.DEPLOY_PORT }}
        source: "Elyes.war"
        target: "/opt/tomcat/webapps"

  deploy:
    name: SAV IPFS
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@master
      - run: |
          jar cvf Elyes.war *
      - uses: jirutka/setup-alpine@v1
        with:
          branch: v3.15
      - run: |
          apk add go-ipfs
          ipfs init
          ipfs daemon &
        shell: alpine.sh --root {0}
      - name: Sauvegarde fichier war sur IPFS
        run: |
          ls -la 
          ipfs swarm peers
          ipfs add Elyes.war > ipfs_key.txt
        shell: alpine.sh --root {0}
      - name: Notification Discord
        env:
          DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
        run: |
          ipfs_key=$(cat ipfs_key.txt | awk '{print $2}')
          curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"Elyes: Le workflow92 IPFS est terminé. Clé IPFS : $ipfs_key\"}" $DISCORD_WEBHOOK
