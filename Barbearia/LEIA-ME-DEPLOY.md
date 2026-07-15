# Black & White Barbearia — Guia de configuração e deploy

Este projeto tem 2 partes:
- **Banco de dados / backend:** Supabase (gratuito para começar)
- **Site:** um único arquivo `index.html`, hospedado em qualquer serviço de site estático (Netlify, Vercel, etc.)

Siga os passos na ordem. Leva uns 15–20 minutos na primeira vez.

---

## Parte 1 — Criar o banco de dados no Supabase

1. Acesse **https://supabase.com** e crie uma conta gratuita.
2. Clique em **New Project**. Escolha um nome (ex: `black-and-white-barbearia`), uma senha forte para o banco (guarde num lugar seguro) e a região mais próxima (ex: São Paulo/`sa-east-1`).
3. Aguarde o projeto ser criado (leva 1–2 minutos).
4. No menu lateral, vá em **SQL Editor** → **New query**.
5. Abra o arquivo `supabase-schema.sql` (que está junto com este guia), copie **todo o conteúdo** e cole no editor.
6. Clique em **Run**. Deve aparecer "Success. No rows returned" — isso confirma que as tabelas, funções e regras de segurança foram criadas.

### Criar o login de cada barbeiro

1. No menu lateral, vá em **Authentication → Users**.
2. Clique em **Add user → Create new user**.
3. Crie um usuário para cada barbeiro com **e-mail** e **senha**. Sugestão de e-mails (você pode usar outros, desde que ajuste o código depois):
   - `thales@blackandwhite.com.br`
   - `marcelo@blackandwhite.com.br`
   - `darlheson@blackandwhite.com.br`
4. Marque a opção **Auto Confirm User** ao criar (assim não precisa confirmar por e-mail).
5. Anote as senhas e repasse para cada barbeiro depois — eles podem trocar a senha futuramente pelo mesmo painel do Supabase, ou você pode implementar um "esqueci minha senha" mais adiante.

> Se quiser usar e-mails diferentes dos sugeridos, lembre de atualizar o objeto `staffDirectory` dentro do `index.html` (explicado na Parte 2).

### Pegar a URL e a chave do projeto

1. No menu lateral, vá em **Project Settings → API**.
2. Copie o valor de **Project URL** (algo como `https://xxxxxxxx.supabase.co`).
3. Copie o valor de **anon public** (uma chave longa, começa com `eyJ...`).
4. Guarde os dois — você vai usar no próximo passo.

---

## Parte 2 — Configurar o site

1. Abra o arquivo `index.html` num editor de texto (Bloco de Notas, VS Code, etc.).
2. Procure por este trecho, perto do topo da tag `<script>`:

```js
const SUPABASE_URL = 'COLE_AQUI_A_URL_DO_SEU_PROJETO_SUPABASE';
const SUPABASE_ANON_KEY = 'COLE_AQUI_A_CHAVE_ANON_PUBLIC';
```

3. Substitua pelos valores que você copiou na Parte 1:

```js
const SUPABASE_URL = 'https://xxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJ...sua-chave-completa-aqui';
```

4. Se usou e-mails diferentes dos sugeridos para os barbeiros, procure por `staffDirectory` no mesmo arquivo e ajuste:

```js
const staffDirectory = {
  'thales@blackandwhite.com.br':    {barberId:'thales',    name:'Thales'},
  'marcelo@blackandwhite.com.br':   {barberId:'marcelo',   name:'Marcelo'},
  'darlheson@blackandwhite.com.br': {barberId:'darlheson', name:'Darlheson'},
};
```
   O `barberId` precisa continuar sendo `'thales'`, `'marcelo'` ou `'darlheson'` — são os identificadores usados nos agendamentos. Só o e-mail muda.

5. Salve o arquivo.

**A chave "anon public" pode ficar visível no código do site** — ela é feita para isso, e as regras de segurança que rodam no SQL (RLS) é que garantem que só barbeiros logados conseguem ver/editar/excluir agendamentos. Nunca use a chave **service_role** (a outra chave, mais poderosa) no site.

---

## Parte 3 — Testar localmente antes de publicar

Antes de publicar, teste no seu computador:

1. Dê duplo clique no `index.html` para abrir no navegador, **ou** (recomendado, evita bloqueios do navegador) rode um servidor local simples:
   ```bash
   # dentro da pasta do projeto
   python3 -m http.server 8000
   ```
   e acesse `http://localhost:8000` no navegador.
2. Teste o fluxo completo de agendamento como cliente.
3. Clique em "Área do barbeiro", entre com um dos e-mails/senhas criados na Parte 1, e confira se o agendamento de teste aparece na lista.
4. Teste editar e excluir um agendamento.

---

## Parte 4 — Publicar o site (deploy)

A forma mais simples e gratuita é o **Netlify**:

1. Acesse **https://app.netlify.com** e crie uma conta gratuita.
2. Na tela inicial, arraste a pasta do projeto (ou só o `index.html`) para a área de upload ("Deploy manually" / "Drag and drop").
3. Em poucos segundos o Netlify gera um endereço público, tipo `https://black-and-white-barbearia.netlify.app`.
4. (Opcional) Em **Site settings → Domain management**, você pode conectar um domínio próprio, tipo `www.blackandwhitebarbearia.com.br`.

Alternativas igualmente boas: **Vercel** (vercel.com) ou **GitHub Pages**, ambas gratuitas para esse tipo de site.

---

## Resumo do que foi construído

- **Cadastro de agendamento (clientes):** grava direto no banco via uma função segura (`create_booking`), sem expor a tabela inteira.
- **Disponibilidade de horários:** consultada em tempo real no banco (`get_booked_times`), não é mais simulada.
- **Painel do barbeiro:** login real via Supabase Auth, cada barbeiro vê todos os agendamentos, pode filtrar pelos seus, editar e excluir — tudo refletido direto no banco de dados.
- **Segurança:** a tabela de agendamentos só pode ser lida, editada ou excluída por usuários autenticados (barbeiros). Clientes anônimos só conseguem criar um agendamento ou consultar horários livres — nunca ver dados de outros clientes.

## Limitações a ter em mente

- Não há confirmação por e-mail/WhatsApp automática ainda — isso pode ser adicionado depois com Supabase Edge Functions + um serviço de e-mail (ex: Resend) ou WhatsApp Business API.
- Não há recuperação de senha configurada na tela de login — pode ser adicionada usando `supabase.auth.resetPasswordForEmail()`.
- Cadastro de novos serviços ou barbeiros hoje exige editar o código (`services`, `barbers`, `staffDirectory`) e o `check` do SQL. Se a barbearia crescer e isso incomodar, dá para migrar para tabelas editáveis no banco — posso te ajudar com isso quando quiser.
