# GAMA App

Frontend mobile e desktop do **GAMA — Gestão Automotiva de Mecânica e Atendimento**, um SaaS multi-tenant para gestão de oficinas mecânicas.

Consome a API REST em [gama-api](../gama-api).

---

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.x (Dart 3.x) |
| Gerenciamento de estado | Riverpod 2 (`AsyncNotifier`) |
| Navegação | go_router com guard reativo |
| HTTP | Dio + interceptor JWT automático |
| Armazenamento seguro | flutter_secure_storage |
| Models | freezed + json_serializable |

---

## Arquitetura

Estrutura feature-first com separação em camadas:

```
lib/
  core/
    network/        → Dio client, interceptor de autenticação, constantes
    storage/        → flutter_secure_storage provider
    router/         → go_router com redirecionamento por AuthState
  features/
    auth/
      data/         → AuthRepository, AuthRemoteDataSource
      domain/       → AuthState, GrupoItem, DTOs (freezed)
      presentation/ → LoginScreen, SelectGroupScreen, AuthNotifier
    home/
      presentation/ → HomeScreen (placeholder)
  shared/
    widgets/        → GamaButton e componentes reutilizáveis
  main.dart
```

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x
- Dart 3.x
- Android Studio / Xcode (para emuladores) ou Chrome / Windows (para web/desktop)
- API GAMA rodando localmente (ver `../gama-api`)

---

## Configuração e execução

### 1. Instalar dependências

```bash
flutter pub get
```

### 2. Gerar código (freezed / json_serializable)

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Rode isso sempre que modificar arquivos com `@freezed` ou `@JsonSerializable`.

### 3. Rodar o app

**Android (emulador)** — a URL padrão já aponta para `10.0.2.2:5000` (localhost do host):
```bash
flutter run
```

**Windows desktop:**
```bash
flutter run -d windows
```

**Chrome (web):**
```bash
flutter run -d chrome
```

**Com URL customizada da API:**
```bash
flutter run --dart-define=BASE_URL=http://192.168.1.100:5000
```

### 4. Listar dispositivos disponíveis

```bash
flutter devices
```

---

## Fluxo de autenticação

```
POST /auth/entrar
       │
       ├── 1 grupo  → token direto → /home
       │
       └── múltiplos grupos → /select-group → seleciona → token → /home
```

O token JWT é persistido com `flutter_secure_storage`. Na próxima abertura do app, se o token existir, o usuário vai direto para `/home`.

---

## Variáveis de ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `BASE_URL` | `http://localhost:5181` | URL base da API |

Configure via `--dart-define=BASE_URL=valor` no `flutter run`.

---

## Build e release de produção

### Pré-requisitos
- GitHub CLI instalado e autenticado (`gh auth login`)
- Keystore em `android/gama-release.jks` + `android/key.properties` configurado

### Subir nova versão

1. Atualize a versão em `pubspec.yaml`:
   ```
   version: X.Y.Z+N   # ex: 1.0.3+4
   ```
   Sempre incremente os dois valores — `X.Y.Z` é o que o usuário vê, `+N` é o build number interno do Android.

2. Rode o script de build e publicação:
   ```bash
   ./build_prod.sh
   ```
   O script builda o APK com a URL de produção, cria a release no GitHub (`queirozsnr/gama-app`) e faz o upload automático do APK.

3. O app detecta a nova versão automaticamente ao abrir e exibe o dialog de atualização para os usuários.
