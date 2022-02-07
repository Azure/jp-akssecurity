# Whitepaper for Azure Kubernetes Service

本ドキュメントでは、Azure Kubernetes Services (AKS) のセキュリティ対策について、よくご質問を受けるポイントに絞って解説しています。ここで取り上げた製品・サービスの詳細および最新情報は、[製品ドキュメント](https://docs.microsoft.com)をご参照ください。なお、本ドキュメントの作成には、[株式会社エーピーコミュニケーションズ様](https://www.ap-com.co.jp/)にご協力をいただきました。

## [はじめに](./chapter00.md)

インフラ基盤のセキュリティ対策の勘所と Kubernetes 脅威マトリクスについて解説します。

## [1章 AKSネットワーキングとセキュリティ](./chapter01.md)

Azure Kubernetes Service (AKS) のネットワーク構成の特徴について説明をした上で、セキュリティ対策のポイントと具体的な参照アーキテクチャを紹介します。

## [2章 セキュリティイベントのモニタリング](./chapter02.md)

Microsoft Defender for Cloud 及び Microsoft Defender for Container を用い AKS 上の運用に際し発生のログをセキュリティの観点でモニタリングする手法を紹介します。

## 3章 秘匿情報の管理(準備中)

Azure Key Vault を用い、データベースのパスワードなど管理に注意が必要な秘匿情報を適切に管理する手法について説明します。

## 4章 セキュアなCI/CDパイプラインの構築(準備中)

Microsoft Defender for Containers を用い CI/CD パイプラインのセキュリティ性を高める手法を紹介します。


## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
