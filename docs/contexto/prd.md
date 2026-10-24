# PRD — webdevbox: Ambiente de Desenvolvimento Portátil e Persistente

## O que é o produto

O webdevbox é um ambiente de desenvolvimento completo, portátil, isolado e persistente, baseado em Arch Linux e distribuído como uma imagem de contêiner construída com Podman a partir de um Dockerfile multi-stage. A imagem é consumida no host através de Distrobox, o que faz o contêiner se integrar ao sistema operacional nativo — aparecendo no terminal do usuário como se fosse a própria máquina, mas com todo o ecossistema de ferramentas versionado, reproduzível e descartável. O projeto é derivado da imagem pública `akitaonrails/webdevbox`, customizada localmente para as necessidades específicas do desenvolvedor, e o repositório carrega o Dockerfile, os helpers de configuração e agora esta documentação de contexto.

## Problemas que resolve

O motivo de existir do ambiente é eliminar a fragilidade clássica de máquinas de desenvolvimento: o "funciona na minha máquina". Ao empacotar editor, shell, gerenciadores de versão de linguagens, clientes de infraestrutura e ferramentas de terminal em uma imagem construída do zero, garantimos que qualquer reconstrução produza um ambiente idêntico, e que um ambiente quebrado possa ser destruído e recriado sem trauma. Isso resolve três dores concretas: a deriva de versões entre o host e os servidores de produção, a poluição do sistema operacional nativo com pacotes e dependências experimentais, e o desgaste do SSD principal com o I/O pesado de caches, compilações e árvores de plugins — problema atacado com o redirecionamento da home interna para um HD mecânico dedicado. Por fim, resolve o problema específico que motivou a versão atual: ambientes de editor que travam, desincronizam ou exibem erros de migração a cada atualização do Neovim e de seus plugins.

## Público e uso

O usuário do produto é o próprio desenvolvedor dono do projeto (o usuário local `gogarx`), trabalhando diariamente em um host BigLinux nativo. Trata-se de uma ferramenta pessoal de produtividade para desenvolvimento web full-stack, na qual o dia a dia acontece dentro do terminal Zsh com Powerlevel10k e dentro do editor LunarVim, com as linguagens e ferramentas de linha de comando (asdf, kubectl, terraform, clientes de banco, entre outros) prontamente disponíveis.

## Escopo da versão atual (v1)

O foco da v1 é a estabilização do ecossistema interno, e não a expansão. Isso significa um terminal Zsh com o tema Powerlevel10k configurado de forma limpa e previsível, e um editor de código "sênior" — o LunarVim — com suas dependências, parsers de Treesitter e servidores de linguagem atualizados e funcionando sem travamentos, alertas de migração ou erros fatais de API. Complementarmente, a v1 estabiliza o próprio pipeline de construção da imagem, garantindo builds verdes e reproduzíveis a partir do Dockerfile. Integrações de novas linguagens, novos servidores de linguagem e expansão da stack de ferramentas ficam explicitamente fora do escopo desta versão e são deixadas para um momento posterior, quando a base estiver consolidada.

## Critérios de sucesso

A v1 é considerada entregue quando: o `podman build` completa do início ao fim sem intervenção manual; a entrada via Distrobox com a home persistente no HD funciona de forma transparente; o LunarVim abre, sincroniza plugins via `:Lazy sync`, atualiza parsers via `:TSUpdate` e servidores via `:MasonUpdate` sem nenhum erro vermelho; e o terminal abre sem ruído visual, com o prompt do Powerlevel10k truncando caminhos longos de forma legível. O estado atual do projeto (Outubro de 2026) atinge esses critérios, conforme registrado no histórico de decisões em `memory.md`.
