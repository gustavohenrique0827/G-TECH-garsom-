# Checklist: iOS/Android — rodar localmente e publicar nas lojas

## Rodar localmente (o que já funciona)

**Android** — validado de ponta a ponta neste projeto (emulador `sdk gphone16k
arm64`, `com.gtech.garcom`): build, instalação, login e dashboard com dados
reais do Supabase, tudo funcionando.

```bash
flutter build apk --debug --dart-define-from-file=config/env.local.json
flutter install -d <device-id>
```

**iOS** — bloqueado numa única etapa que só você pode fazer (precisa da sua
Apple ID; eu não tenho como logar por você):

1. Abra o Xcode → **Settings → Accounts** → `+` → entre com sua Apple ID
   (uma conta grátis já é suficiente para rodar no seu iPhone/simulador;
   só é paga se for publicar na App Store).
2. Abra `ios/Runner.xcworkspace` no Xcode.
3. Selecione o target **Runner** → aba **Signing & Capabilities** →
   marque "Automatically manage signing" → escolha seu Team no dropdown.
4. Com o iPhone conectado, na primeira instalação vá em
   **Ajustes → Geral → VPN e Gerenciamento de Dispositivo** no iPhone e
   confie no seu certificado de desenvolvedor.
5. Depois disso, `flutter run -d <iphone-id> --dart-define-from-file=config/env.local.json`
   funciona normalmente.

Já corrigi dois problemas que travariam esse build de qualquer forma:
- `mobile_scanner` estava nas dependências sem nunca ser usado no código
  (o app *gera* QR Code, não escaneia) — puxava o Google ML Kit e quebrava
  o simulador em Macs Apple Silicon. Removido.
- `IPHONEOS_DEPLOYMENT_TARGET` estava em 13.0; subi para 15.5.

## Antes de publicar nas lojas

Nada disso eu posso fazer sem acesso às suas contas — são credenciais e
decisões de negócio (nome público, categoria, preço, etc.).

### Ícone e splash screen
- `flutter_launcher_icons` e `flutter_native_splash` já estão nas
  dependências, mas sem configuração nem imagem-fonte — hoje o app usa o
  ícone padrão do Flutter em todas as plataformas.
- Quando tiver a logo do GTech Garçom (PNG, fundo transparente, ideal
  1024×1024), me mande o arquivo que eu configuro os dois pacotes e gero
  os ícones/splash para iOS, Android e Web de uma vez.

### Apple App Store
- Conta Apple Developer (US$99/ano) em https://developer.apple.com.
- Criar o App ID `com.gtech.garcom` no portal, e o registro do app no
  App Store Connect (nome, categoria, screenshots, política de
  privacidade — obrigatória, já que o app usa autenticação e dados de
  localização/estabelecimento).
- Assinatura de release: criar um certificado de distribuição e
  provisioning profile (via Xcode ou Fastlane) — diferente do certificado
  de desenvolvimento usado para rodar no seu iPhone.

### Google Play Store
- Conta Google Play Console (US$25, pagamento único) em
  https://play.google.com/console.
- Gerar uma keystore de assinatura de release e configurar
  `android/key.properties` (hoje o `build.gradle.kts` assina o release
  com a chave de debug — **isso precisa mudar antes de publicar**, a
  Play Store não aceita builds assinados com debug key).
- Preencher a ficha da loja (nome, descrição, screenshots, política de
  privacidade, classificação indicativa).

### Antes de qualquer publicação
- Trocar as senhas de teste (`admin@gtech.com.br`, `ze@bardoze.com.br`)
  criadas durante o desenvolvimento.
- Apontar `CLIENT_BASE_URL` (hoje `https://garcom.gtech.com.br`) para o
  domínio real de produção da PWA do cliente, e gerar
  `config/env.local.json` de produção separado do de desenvolvimento.
