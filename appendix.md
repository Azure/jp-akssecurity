# Appendix

## 参考リンク集
各章の記載内容について参考となるリンクを紹介します。  
本文と合わせ、各リンク先の記載ついてもご一読ください。

■　[はじめに](chapter00.md)  
Secure containerized environments with updated threat matrix for Kubernetes  
https://www.microsoft.com/security/blog/2021/03/23/secure-containerized-environments-with-updated-threat-matrix-for-kubernetes/

■　[第1章](chapter01.md)  
Azure Application Gateway 上の Azure Web アプリケーション ファイアウォール  
https://docs.microsoft.com/ja-jp/azure/web-application-firewall/ag/ag-overview

Azure Firewall  
https://docs.microsoft.com/ja-jp/azure/firewall/overview

■　[第2章](chapter02.md)  
Microsoft Defender for Cloud  
https://docs.microsoft.com/ja-jp/azure/defender-for-cloud/defender-for-cloud-introduction

Microsoft Defender for Containers  
https://docs.microsoft.com/ja-jp/azure/defender-for-cloud/defender-for-containers-introduction?tabs=defender-for-container-arch-aks

■　[第3章](chapter03.md)  
Azure Key Vault  
https://docs.microsoft.com/ja-jp/azure/key-vault/general/overview

■　[第4章](chapter04.md)  
Kubernetes 用の Azure Policy について理解する  
https://docs.microsoft.com/ja-jp/azure/governance/policy/concepts/policy-for-kubernetes

MITRE ATT&CK® フレームワークのセキュリティ カバレッジについて  
https://docs.microsoft.com/ja-jp/azure/sentinel/mitre-coverage



## Azure Review Checklists
第 1 章から第 4 章までを通じ、様々な観点で Azure Kubernetes Service のセキュリティに関して解説しました。  
Azure Kubernetes Service を用いたシステムを構築する際の支援ツールとして GitHub の Azure リポジトリにてチェックリストが公開されています。

https://github.com/Azure/review-checklists

実際に Microsoft の FastTrack チームが利用しているもので、設計構築の観点がチェックリストの形に纏められており、回答結果を基にスコアを表示できます。このチェックリストを利用することで、セキュリティの観点に限らず可用性や運用の観点からもベスト プラクティスを取り入れることができます。  