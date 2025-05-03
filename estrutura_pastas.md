# Estrutura de Pastas Recomendada

```
project_root/
├── lib/
│   ├── core/
│   │   ├── constants/               # Constantes da aplicação
│   │   ├── errors/                  # Tratamento de erros
│   │   ├── utils/                   # Funções utilitárias
│   │   └── themes/                  # Temas e estilos
│   │
│   ├── data/
│   │   ├── datasources/             # Fontes de dados (local, remoto)
│   │   ├── models/                  # Modelos de dados (classes)
│   │   └── repositories/            # Implementações de repositórios
│   │
│   ├── domain/
│   │   ├── entities/                # Entidades de domínio
│   │   ├── repositories/            # Interfaces de repositórios
│   │   └── usecases/                # Casos de uso da aplicação
│   │
│   ├── presentation/
│   │   ├── pages/                   # Telas da aplicação
│   │   ├── widgets/                 # Widgets reutilizáveis
│   │   └── controllers/             # Controladores/gerenciadores de estado
│   │
│   ├── config/                      # Configurações da aplicação
│   ├── localization/                # Internacionalização (se aplicável)
│   ├── routes/                      # Definição de rotas
│   └── main.dart                    # Ponto de entrada da aplicação
│
├── assets/
│   ├── images/                      # Imagens e ícones
│   ├── fonts/                       # Fontes personalizadas
│   └── data/                        # Arquivos JSON ou outros dados estáticos
│
├── test/
│   ├── unit/                        # Testes unitários
│   ├── widget/                      # Testes de widgets
│   └── integration/                 # Testes de integração
│
├── pubspec.yaml                     # Configuração de dependências
└── README.md                        # Documentação do projeto
```

Esta estrutura segue os princípios de Clean Architecture, separando claramente as responsabilidades e tornando o código mais modular, testável e mantível.