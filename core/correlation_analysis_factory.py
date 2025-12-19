from abc import ABC, abstractmethod
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

class AnalysisStrategy(ABC):
    @abstractmethod
    def analyze(self, data, features, targets):
        pass

    def generic_visualization(self, data, features, targets):
        correlation_matrix = data[features + targets].corr().dropna(how='all', axis=0).dropna(how='all', axis=1)
        plt.figure(figsize=(12, 8))
        sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', fmt=".2f", linewidths=0.5, cbar=True)
        plt.title('Feature vs. Target Correlation Matrix', fontsize=16)
        plt.xticks(rotation=45, ha='right', fontsize=12)
        plt.yticks(rotation=0, fontsize=12)
        plt.tight_layout()
        plt.show()

        for target in targets:
            for feature in features:
                plt.figure(figsize=(8, 5))
                sns.regplot(x=data[feature], y=data[target], scatter_kws={'alpha': 0.5}, line_kws={'color': 'red'})
                plt.xlabel(feature)
                plt.ylabel(target)
                plt.title(f'Impact of {feature} on {target}')
                plt.tight_layout()
                plt.show()

    def visualize_correlation(self, features, targets, results, owner):
        pearson_corr_df = pd.DataFrame({
            target: {
                feature: (
                    results.get(target, {})
                    .get(feature, {})
                    .get('pearson_corr')
                )
                for feature in features
                if results.get(target, {}).get(feature, {}).get('pearson_corr') is not None
            }
            for target in targets

        })
        spearman_corr_df = pd.DataFrame({
            target: {
                feature: (
                    results.get(target, {})
                    .get(feature, {})
                    .get('spearman_corr')
                )
                for feature in features
                if results.get(target, {}).get(feature, {}).get('spearman_corr') is not None
            }
            for target in targets
        })

        plt.figure(figsize=(12, 6))
        sns.heatmap(pearson_corr_df, annot=True, cmap="coolwarm", fmt=".2f", linewidths=0.5)
        plt.title(f"Pearson Correlation Heatmap for {owner}")
        plt.xticks(rotation=45, ha='right')
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.show()

        plt.figure(figsize=(12, 6))
        sns.heatmap(spearman_corr_df, annot=True, cmap="coolwarm", fmt=".2f", linewidths=0.5)
        plt.title(f"Spearman Correlation Heatmap for {owner}")
        plt.xticks(rotation=45, ha='right')
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.show()

    def visualize_pca(self, results):
        """
        Visualizes PCA results:
        1. Scree Plot for explained variance.
        2. 2D scatter plot of the first two principal components (if available).
        3. Feature loadings for the first two principal components.
        """
        explained_variance = results["explained_variance"]
        principal_components = results["principal_components"]
        loadings = results["loadings"]
        features = results["features"]
        plt.figure(figsize=(8, 5))
        plt.bar(range(1, len(explained_variance) + 1), explained_variance, color='blue', alpha=0.7)
        plt.xlabel('Principal Component')
        plt.ylabel('Variance Explained')
        plt.title('PCA Explained Variance (Scree Plot)')
        plt.xticks(range(1, len(explained_variance) + 1))
        plt.tight_layout()
        plt.show()

        if principal_components.shape[1] >= 2:
            plt.figure(figsize=(8, 5))
            plt.scatter(principal_components[:, 0], principal_components[:, 1], alpha=0.5, edgecolors='k')
            plt.xlabel("Principal Component 1")
            plt.ylabel("Principal Component 2")
            plt.title("PCA: First Two Principal Components")
            plt.tight_layout()
            plt.show()

        if loadings.shape[0] >= 2:
            plt.figure(figsize=(8, 5))
            plt.barh(features, loadings[0], color='green', alpha=0.7)
            plt.xlabel("Loading Value")
            plt.ylabel("Feature")
            plt.title("Feature Loadings for PC1")
            plt.tight_layout()
            plt.show()

            plt.figure(figsize=(8, 5))
            plt.barh(features, loadings[1], color='orange', alpha=0.7)
            plt.xlabel("Loading Value")
            plt.ylabel("Feature")
            plt.title("Feature Loadings for PC2")
            plt.tight_layout()
            plt.show()

    def visualize_anova(self, features, results):
        """
        Visualizes ANOVA results using bar plots.
        """
        f_stats = {
            target: [results[target][feature]['f_stat'] if feature in results[target] else 0 for feature in features]
            for target in results}
        p_values = {
            target: [results[target][feature]['p_value'] if feature in results[target] else 1 for feature in features]
            for target in results}

        f_stats_df = pd.DataFrame(f_stats, index=features)
        p_values_df = pd.DataFrame(p_values, index=features)

        plt.figure(figsize=(12, 6))
        sns.heatmap(f_stats_df, annot=True, cmap="Blues", fmt=".2f", linewidths=0.5)
        plt.title("ANOVA F-Statistics Heatmap")
        plt.xticks(rotation=45, ha='right')
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.show()

        plt.figure(figsize=(12, 6))
        sns.heatmap(p_values_df, annot=True, cmap="Reds", fmt=".2e", linewidths=0.5)
        plt.title("ANOVA P-Values Heatmap")
        plt.xticks(rotation=45, ha='right')
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.show()
