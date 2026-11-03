# Banco de Talentos Audiovisual

**TCC — Desenvolvimento de um Banco de Talentos Geolocalizado para a Indústria
Audiovisual: Uma Abordagem Utilizando Flutter e Computação Espacial.**

Aplicativo Android, feito em Flutter, que permite encontrar profissionais
técnicos do audiovisual (diretores de fotografia, técnicos de som, gaffers,
operadores de steadicam...) **próximos a um ponto no mapa**, usando a
localização GPS do celular e uma busca por raio (em km).

---

## Arquitetura

O projeto segue a **Clean Architecture** (Arquitetura Limpa), organizada por
**módulos** (funcionalidades). Cada módulo tem três camadas:

```
supabase/schema.sql                -> banco de dados (tabelas, PostGIS, segurança)
lib/
├── main.dart                      -> ponto de entrada (conecta Supabase e DI)
├── app.dart                       -> widget raiz (tema, idioma, AuthGate)
├── core/                          -> código compartilhado por todos os módulos
│   ├── config/                    -> variáveis de ambiente (chaves do Supabase)
│   ├── presentation/              -> estado genérico de listas (ListState)
│   ├── constants/                 -> funções do audiovisual (lista padronizada)
│   ├── network/                   -> tradução de erros do Supabase em Failures
│   ├── di/                        -> injeção de dependências (GetIt + injectable)
│   ├── error/                     -> Exceptions (camada de dados) e Failures (domínio)
│   ├── services/location/         -> serviço de GPS (Geolocator)
│   ├── theme/                     -> tema visual do app
│   ├── utils/                     -> validações e formatação (R$, datas, km)
│   ├── widgets/                   -> componentes reutilizáveis (avatar, mapas,
│   │                                 barra de busca estilo Airbnb)
│   └── usecases/                  -> contrato base dos casos de uso
└── modules/
    ├── applications/              -> candidaturas e processo seletivo
    ├── auth/                      -> login, cadastro e sessão (SessionCubit)
    ├── chat/                      -> mensagens em tempo real (após a contratação)
    ├── account/                   -> conta, modo de uso, dados e privacidade (TEL20 a TEL22)
    ├── explore/                   -> modo Contratar: Explorar, busca, resultados e projetos
    ├── profile/                   -> perfil, foto, currículo e papéis
    ├── reviews/                   -> avaliações (estrelas + comentários)
    ├── home/                      -> Início (categorias, vagas perto, atalhos), troca de modo
    ├── jobs/                      -> vagas: publicar (mapa), minhas vagas,
    │                                 busca Onde + Quando + Função (PostGIS)
    ├── notifications/             -> sino 🔔 com avisos em tempo real
    ├── onboarding/                -> ativação dos perfis (TEL05 a TEL09) e localização
    ├── payments/                  -> garantia, carteira e saques (simulados)
    ├── portfolio/                 -> perfil estilo LinkedIn: capa, experiências e portfólio
    ├── professional/              -> modo Profissional: Painel, Meu perfil e edição (TEL16 a TEL18)
    └── talent_search/             -> busca de talentos original (camadas de domínio e dados)
        ├── domain/                -> REGRAS DE NEGÓCIO (Dart puro)
        │   ├── entities/          -> ProfessionalEntity, LocationEntity
        │   ├── repositories/      -> contrato TalentRepository
        │   └── usecases/          -> SearchTalentsByRadiusUseCase
        └── data/                  -> ACESSO A DADOS
            ├── models/            -> ProfessionalModel (conversão JSON)
            ├── datasources/       -> chamadas ao Supabase (RPC)
            └── repositories/      -> TalentRepositoryImpl
```

### Perfil único com dois papéis

Como no Airbnb (em que o hóspede pode "tornar-se anfitrião"), cada pessoa tem
**uma única conta** que pode ser:

- **Profissional**: oferece serviços e se candidata a vagas;
- **Contratante**: publica vagas e seleciona profissionais;
- **ou os dois**, alternando entre os modos na tela inicial.

No banco, isso são as colunas `is_professional` e `is_recruiter` da tabela
`profiles`, com a regra de que pelo menos uma seja verdadeira.

### Identidade visual (CineCrew)

O app se chama **CineCrew** e segue o design system da documentação visual da equipe
(`Documentacao_Visual_CineCrew.pdf`, seção 3): tema **claro**, azul-marinho `#17324D` como cor
primária e âmbar `#E8A33D` como destaque (ação principal de busca e criação). Cores, tipografia,
raios e botões ficam em `lib/core/theme/` (`app_colors.dart` e `app_theme.dart`).

Componentes do design system: banner de mensagem (`AppBanner`: erro, sucesso, alerta, informação),
campo com rótulo em cima (`LabeledField`) e a ilustração de set desenhada em código
(`SetIllustration`, sugestão S01 — sem fotos de pessoas).

Telas de acesso conforme as pranchas: **TEL01** Boas-vindas, **TEL02** Entrar (com o banner
TEL02-E1), **TEL03** Criar conta (erros por campo, TEL03-E1) e **TEL04** "Como você quer começar?".
A conta nasce sem perfil e a pessoa escolhe o primeiro modo (proposta P17: uma conta, dois modos).

### Ativação dos perfis, LGPD e posição aproximada

- **Perfil profissional em 4 passos** (TEL05 a TEL08): dados profissionais, especialidades do
  catálogo (a primeira vira a função principal), **aceite do uso da localização** (registrado com
  data, hora e versão do termo) e "Onde você atua" — por endereço, CEP, toque no mapa ou GPS.
- **Modo Contratar** (TEL09): nome do responsável e produtora (CNPJ não exigido nesta versão).
- **Geocodificação** (decisão P04): CEP pelo ViaCEP e endereço -> coordenada pelo Nominatim
  (OpenStreetMap). Endereço ambíguo mostra opções; não encontrado mostra o estado TEL08-E2;
  permissão de GPS negada leva ao mapa (TEL08-E1).
- **Privacidade (RN35/RN36):** ninguém lê a coordenada exata de outra pessoa — o banco só libera
  a **posição aproximada** (grade de ~1,1 km). A busca usa a coordenada exata para decidir
  `d <= R`, mas devolve a posição aproximada e a distância arredondada ("≈ 5 km").
  Sem aceite em vigor, o profissional não aparece nas buscas.

### Modo Profissional e Conta (TEL16 a TEL22)

Abas do modo Profissional: **Painel · Perfil · Vagas · Mensagens · Conta**
(Vagas e Mensagens são extras; "Minhas candidaturas" fica no Painel e na aba Vagas).

- **Painel (TEL16):** cartão "Seu perfil aparece nas buscas" com a lista de verificação, interruptor
  "Disponível para novos trabalhos", atalhos Editar perfil e Portfólio; extras: candidaturas, carteira,
  vagas por categoria e vagas perto de você.
- **Meu perfil (TEL17):** capa e foto, "Visível / Não visível nas buscas" (TEL17-E1), especialidades,
  localização-base (Alterar abre a TEL08), portfólio, currículo e "Ver como os contratantes veem".
- **Editar dados profissionais (TEL18):** nome, contato, especialidades, título e "Sobre você".
- **Conta e modo de uso (TEL20):** troca de modo com a transição "Alternando para o modo..." (TEL20-E1),
  convite para ativar o modo que falta (TEL20-E2), dados da conta, dados da produtora, carteira,
  privacidade e sair. O app abre no **último modo usado** (P20).
- **Dados da conta (TEL21):** nome, e-mail (com link de confirmação) e senha.
- **Privacidade e dados (TEL22):** revogar o aceite (TEL22-E2), desativar a conta e excluir conta e
  dados (TEL22-E1, com confirmação "Entendo que a exclusão é definitiva"). Conta desativada só entra
  para reativar (TEL02-E2, decisão P01). A exclusão apaga os arquivos e, em cascata, todos os dados.

### Modo Contratar (TEL10 a TEL15)

Abas: **Explorar · Projetos · Vagas · Mensagens · Perfil** (Vagas e Mensagens são extras do app).

- **Explorar (TEL10):** cartão de busca com "Onde é o set?", especialidades e raio; botão de destaque
  "Buscar profissionais"; projetos recentes; indicador de modo ⇄ no topo.
- **Definir busca e projeto (TEL11):** local do set (mesma tela de localização da TEL08), várias
  especialidades, raio de 1 a 200 km (P05) e nome do projeto opcional — com nome, o projeto é salvo.
  Erros por campo (TEL11-E1).
- **Resultados (TEL12/TEL13):** lista ordenada por distância com cartões ilustrados e "≈ N km do set";
  botão flutuante Mapa/Lista; mapa com o círculo do raio, pino do set e balões de distância na posição
  aproximada. Estados: carregando (esqueleto), nenhum profissional, erro com "Tentar novamente" e painel
  de filtros (especialidades, raio, somente disponíveis).
- **Perfil do profissional (TEL14):** perfil público com "≈ N km do set · localização aproximada".
- **Meus projetos (TEL15):** repetir, editar ou apagar buscas salvas; estado vazio (TEL15-E1).
- Banco: tabela `projects` (privada, RLS) e função `search_talents` — **qualquer uma** das
  especialidades (P06), filtro de disponíveis, até 100 resultados (P11), mesmas regras de privacidade.

### Busca de vagas no estilo Airbnb

O profissional busca vagas pelos mesmos três critérios do Airbnb:

| Airbnb | Banco de Talentos | Como é calculado |
|---|---|---|
| Onde | ponto (GPS ou perfil) + raio em km | `ST_DWithin` do PostGIS |
| Quando | período desejado | sobreposição de datas (`ends_at >= início` e `starts_at <= fim`) |
| Quem | função procurada | `ILIKE` na função da vaga |

O resultado vem ordenado pela distância (`ST_Distance`), da vaga mais
próxima para a mais distante.

### Pagamento com garantia, carteira e saque (SIMULADO)

Inspirado na Garantia OLX. **Nenhum dinheiro real é movimentado.**

```
proposta aceita ─► aguardando pagamento ─► em garantia 🔒 ─► liberado ✅ ─► carteira ─► saque (Pix/TED)
                    (contratante paga)      (os dois confirmam)                  └──► em disputa ⚠️
```

- Quando o profissional aceita a proposta, o banco cria o pagamento com o valor do cachê.
- O contratante "paga" (Pix ou cartão, simulados) e o valor fica **retido**.
- Depois do serviço, **os dois confirmam**. Aí o valor entra na **carteira** do profissional.
- O profissional cadastra a **conta para receber** (chave Pix e/ou banco, agência e conta para TED)
  e pede o **saque**. O app valida CPF/CNPJ pelos dígitos verificadores.
- Todas as operações com dinheiro são **funções do banco** (`pay_escrow`, `confirm_service`,
  `open_payment_dispute`, `request_withdrawal`), que conferem quem pede, o estado atual e o saldo.
  O app não consegue alterar essas tabelas diretamente.

Para virar dinheiro de verdade, essas funções seriam trocadas por chamadas a um intermediador de
pagamentos autorizado pelo Banco Central, com conta de custódia e verificação de identidade.

### Perfil estilo LinkedIn

- **Capa** (foto larga no topo) + foto de perfil sobreposta, nome, **título profissional**
  (ex.: "Videomaker de casamentos · 8 anos de set"), função, cidade e nota média.
- **Experiência**: trabalhos anteriores com função, produção, tipo de projeto (filme, clipe,
  publicidade...) e período ("mar. 2024 – atual · 8 meses").
- **Portfólio**: fotos (enviadas para a pasta pública `portfolio` do Storage) e vídeos (links do
  YouTube, Vimeo, Instagram...). Vídeos do YouTube ganham miniatura automática.
- Tudo é editado em Perfil → "Portfólio e experiências", e o botão "Ver como os outros veem"
  abre o perfil público. Limite de 30 itens de cada tipo (conferido pelo banco).

### Avaliações (estilo recomendações do LinkedIn)

- Depois da contratação (e do pagamento liberado, quando a vaga tem cachê), **cada lado avalia o
  outro** com 1 a 5 estrelas e um comentário opcional. Só uma avaliação por lado em cada contratação.
- A **média** e a **quantidade** ficam no perfil (`profiles.rating` e `profiles.reviews_count`),
  recalculadas pelo banco. O usuário não consegue alterar a própria nota.
- O **perfil público** mostra a média e os comentários, e a busca de talentos mostra a nota (★ 4,7).
- Regras na função `submit_review`; lista pública pela função `get_reviews`.

### Mapas (computação espacial na tela)

| Onde | O que mostra |
|---|---|
| Início (profissional) | carrossel de categorias + "Vagas perto de você" (até 50 km do perfil) com mini mapas |
| Buscar vagas | botão 🗺 alterna entre lista e **mapa** com o círculo do raio e o cachê de cada vaga |
| Talentos perto do set (contratante) | mapa com o raio e um marcador com nome e ícone da função de cada profissional |
| Publicar vaga | o contratante toca no mapa (ou usa o GPS) para marcar o local do set |
| Detalhe da vaga / Candidaturas | mini mapa com o pino no local |

Os mapas usam `flutter_map` com os blocos do OpenStreetMap (sem chave de API).
O zoom inicial acompanha o raio: dobrar o raio afasta o mapa em 1 nível
(`RadiusMap.zoomForRadius`).

### Processo seletivo

```
pendente ──► aprovado p/ entrevista ──► proposta enviada ──► contratado ──► 💬 chat liberado
   │                  │                        └──────────► proposta recusada
   └──► reprovado ◄───┘
```

- O **contratante** aprova para entrevista, reprova ou envia a proposta ("Contratar").
- O **profissional** aceita ou recusa a proposta. O chat só é liberado após o aceite.
- Cada mudança gera uma **notificação** automática (gatilho no banco) para a outra pessoa.
- O **chat** usa o Supabase Realtime: as mensagens chegam na hora, com indicação
  de enviada (✓) e lida (✓✓).
- As regras são verificadas **duas vezes**: no app (casos de uso) e no banco
  (gatilho `validate_application_status`), então ninguém consegue pular etapas.

### Fluxo de uma busca

```
Tela  ->  UseCase  ->  Repository  ->  DataSource  ->  Supabase (PostgreSQL + PostGIS)
          (valida)     (Exception      (RPC
                        -> Failure)     search_professionals)
```

1. A tela pede a posição atual ao `LocationService` (GPS).
2. O caso de uso valida latitude, longitude e raio.
3. O repositório chama o DataSource.
4. O DataSource chama a função SQL `search_professionals` no Supabase.
5. O PostGIS calcula quem está dentro do raio (`ST_DWithin`) e a distância
   de cada um (`ST_Distance`), e devolve a lista ordenada.
6. O resultado volta como `Either<Failure, List<ProfessionalEntity>>`.

---

## Back-end (Supabase)

O banco de dados fica no arquivo [`supabase/schema.sql`](supabase/schema.sql):
tabelas de perfis, vagas, candidaturas, chat e pagamentos em custódia
(simulado), funções de busca espacial, regras de segurança (RLS) e pastas de
arquivos (fotos e currículos).

**Configurando pela primeira vez:**

1. Crie um projeto gratuito em https://supabase.com
2. No painel, abra **SQL Editor**, cole todo o `supabase/schema.sql` e clique em **Run**.
3. Em **Project Settings > API**, copie a *Project URL* e a *anon public key*.
4. Copie `env.example.json` para `env.json` e cole os dois valores.
   O `env.json` está no `.gitignore` e **não vai para o GitHub**.

## Como rodar

```bash
# 1. Baixar as dependências
flutter pub get

# 2. Gerar o código da injeção de dependências
#    (rodar de novo sempre que criar/alterar classes com @injectable)
dart run build_runner build

# 3. Verificar erros e boas práticas
flutter analyze

# 4. Rodar os testes
flutter test

# 5. Rodar no emulador/celular Android (lendo as chaves do env.json)
flutter run --dart-define-from-file=env.json
```

---

## Tecnologias

| Pacote | Para que serve |
|---|---|
| `flutter_bloc` | Gerenciamento de estado (padrão BLoC) |
| `equatable` | Comparação de objetos por valor |
| `get_it` + `injectable` | Injeção de dependências |
| `fpdart` | Tratamento de erros com `Either` |
| `geolocator` | Coordenadas do GPS e permissão de localização |
| `flutter_map` + `latlong2` | Mapas e cálculos geográficos |
| `supabase_flutter` | Banco PostgreSQL/PostGIS, login, arquivos e tempo real |
