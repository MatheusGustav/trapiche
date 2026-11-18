# Trapiche

Dock com widgets ao vivo para o KDE Plasma 6. É um plasmoide: fica dentro de um painel do Plasma e mostra uma fileira de blocos (bateria, apps, pasta, música, clima e outros).

## Instalar

```sh
kpackagetool6 -t Plasma/Applet -i package    # primeira vez
kpackagetool6 -t Plasma/Applet -u package    # atualizar
```

Depois, crie um painel vazio no Plasma e adicione o widget "Trapiche" a ele. A dock troca o fundo do painel por uma barra de vidro que cobre o painel inteiro, então outros widgets do Plasma (a bandeja do sistema, por exemplo) podem ficar no mesmo painel. O vidro é transparente, sem desfoque: a dock deixa o painel sem fundo. A altura do painel define o tamanho dos blocos (o desenho foi feito para 77 px). Painel vertical não é suportado.

Num painel que se esconde ("Auto-ocultar" ou "Desviar de janelas"), a tecla escolhida nas opções da biblioteca mostra a dock por cima das janelas; o atalho de novo, ou o mouse saindo da dock, a esconde.

Os widgets são escolhidos na biblioteca: botão direito na dock, "Widgets…". Ela mostra todos funcionando, por categoria e com busca; clicar num widget o põe na dock ou o tira dela, e enquanto ela está aberta cada bloco da dock ganha um botão vermelho de tirar. Cada bloco fica onde for solto: segure o clique num bloco até ele se soltar e arraste para qualquer ponto da barra. Solto em cima de outro, ele vai para o espaço vazio mais perto, sem mexer nos outros; soltar longe da dock o devolve ao lugar. A posição é guardada como a distância até a borda mais próxima da barra, então o que está perto de um canto continua nele numa barra de outra largura; se a barra ficar estreita demais, os blocos se encostam e, num painel sem largura para todos, encolhem juntos até caber. Antes do primeiro arraste, os widgets de data e hora ficam encostados no canto direito e todos os outros no esquerdo; um widget novo entra no primeiro espaço vazio desse mesmo lado. "Ordem padrão", na biblioteca, volta a esse arranjo. Arrastar um aplicativo (da área de trabalho, do menu ou do gerenciador de arquivos) para o bloco "Aplicativos" o deixa fixado; arrastar um arquivo ou uma pasta cria um atalho ali. Arrastar um link de site (do navegador, por exemplo) para qualquer ponto da dock o fixa como um aplicativo, com o ícone grande que o site publica e de cantos arredondados, ou um quadrado com a inicial quando o site não tem um; ele abre no navegador padrão, entra em pasta como os outros e, ao ser desafixado, é apagado. Arrastar o ícone de um aplicativo para cima de outro junta os dois numa pasta ali mesmo; arrastar para cima de uma pasta põe o aplicativo nela. O aplicativo que está numa pasta aparece só dentro dela, mesmo aberto. Com a pasta aberta, arrastar um aplicativo para fora dela o devolve à dock; a pasta que ficaria com um aplicativo só é desfeita. O botão direito num ícone fixa ou desafixa; numa pasta, a desfaz; num aplicativo dentro dela, o tira de lá. A entrada "Opções" da biblioteca tem a tecla que mostra a dock e as opções de cada widget que está nela; o que se muda ali vale na hora. A "Pasta de aplicativos" pode entrar várias vezes na dock; os aplicativos de cada uma são escolhidos ali.

Num painel, a dock guarda notas adesivas atrás da barra: de cada uma aparece só uma aba colorida em cima do vidro, a partir do começo da dock. Passar o mouse levanta a aba; clicar faz a nota subir de trás da barra, com o texto, a escolha de cor e a lixeira. A aba com "+" cria uma nota; a nota fechada sem texto some. As abas ficam numa janela própria, presa à do painel, e somem e aparecem junto com ele.

## Dependências

Além do Plasma 6: `qdbus-qt6`, `wpctl`, `nmcli`, `bluetoothctl` e `kioclient`, usados pelos widgets de brilho, áudio, rede e lixeira.

O widget Pasta abre um pequeno gerenciador de arquivos e usa `python3`, `gio` (lixeira) e `wl-copy`/`wl-paste` (copiar e colar arquivos com outros programas). A ordem de cada pasta, inclusive a arrumação feita arrastando, fica em `~/.local/share/trapiche/pastas.json`.

Clima, criptomoeda, câmbio e ações consultam serviços públicos pela internet (Open-Meteo, Binance, open.er-api.com e Yahoo Finance).

O link de site fixado na dock usa `python3` e consulta o próprio site, uma vez, para achar o nome e o ícone. O lançador fica em `~/.local/share/applications/trapiche-site-*.desktop`, fora do menu de aplicativos, e o ícone em `~/.local/share/trapiche/sites`.

Os widgets do GitHub usam o login do `gh` (`gh auth login`). Os do Claude Code usam `python3`. O modelo mais usado sai dos registros locais (`~/.claude/projects`). As porcentagens do plano chegam pela linha de status do Claude Code, que precisa apontar para o script do pacote em `~/.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "python3 ~/.local/share/plasma/plasmoids/io.github.matheusgustav.trapiche/contents/code/linha-de-status.py"
}
```

O script grava os limites em `~/.cache/trapiche` e não imprime nada. Os números só mudam enquanto o Claude Code está aberto; se o Trapiche for desinstalado, essa entrada precisa sair do `settings.json`.

## Desenvolvimento

`dev/foto.sh saida.png` roda o plasmoide num compositor virtual, fora da tela e com configuração descartável, e salva uma foto. As variáveis `WIDGETS`, `OPCOES`, `DADOS` e `ABRIR` montam o cenário.

O catálogo de widgets fica em `package/contents/ui/catalogo.js`; cada widget é um arquivo em `package/contents/ui/widgets/`.

## Licença

Copyright (C) 2026 Gustav

O Trapiche é software livre: pode ser redistribuído e modificado nos termos da GNU General Public License, versão 2 ou, à escolha de quem usa, qualquer versão posterior. É distribuído sem nenhuma garantia. O texto da licença está em `LICENSE`.

Os logotipos do GitHub e do Claude, em `package/contents/images`, são marcas dos seus donos e não estão sob essa licença.
