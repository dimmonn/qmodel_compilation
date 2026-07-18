from core.correlation_analysis_factory import AnalysisStrategy
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score, mean_squared_error
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import squarify

import pandas as pd

class RandomForestAnalysis(AnalysisStrategy):
    def __init__(self, n_estimators=200, random_state=42, max_depth=None):
        self.n_estimators = n_estimators
        self.random_state = random_state
        self.max_depth = max_depth

    def analyze(self, data, features, targets):
        results = {}

        for target in targets:
            train_data = data[data['dataset_split'] == 'train']
            valid_data = data[data['dataset_split'] == 'validation']

            X_train = train_data[features]
            y_train = train_data[target]

            X_valid = valid_data[features]
            y_valid = valid_data[target]
            model = RandomForestRegressor(
                n_estimators=self.n_estimators,
                random_state=self.random_state,
                max_depth=self.max_depth,
                n_jobs=-1
            )
            model.fit(X_train, y_train)

            y_pred = model.predict(X_valid)

            mse = mean_squared_error(y_valid, y_pred)
            r2 = r2_score(y_valid, y_pred)

            results[target] = {
                "model": model,
                "r2_score": r2,
                "mse": mse,
                "y_true": y_valid,
                "y_pred": y_pred,
                "feature_importances": model.feature_importances_,
            }
        return results


    def visualize_importance(self, results, features, owner):
        for target, res in results.items():
            importances = res["feature_importances"]
            sorted_idx = np.argsort(importances)[::-1]
            sorted_features = np.array(features)[sorted_idx]
            sorted_importances = importances[sorted_idx]
            plt.figure(figsize=(10, 6))
            sns.barplot(x=sorted_importances, y=sorted_features, palette="viridis")
            plt.title(f"Feature Importances for predicting {target} for {owner}")
            plt.xlabel("Importance")
            plt.ylabel("Feature")
            plt.tight_layout()
            plt.show()

    def visualize_prediction_fit(self, results, owner):
        for target, res in results.items():
            plt.figure(figsize=(6, 5))
            sns.scatterplot(x=res["y_true"], y=res["y_pred"], alpha=0.6)
            plt.plot([res["y_true"].min(), res["y_true"].max()],
                     [res["y_true"].min(), res["y_true"].max()], 'r--')
            plt.xlabel("Actual")
            plt.ylabel("Predicted")
            plt.title(f"Actual vs Predicted: {target} for {owner}")
            plt.tight_layout()
            plt.show()

    def visualize_residuals(self, results, owner):
        for target, res in results.items():
            residuals = res["y_true"] - res["y_pred"]
            plt.figure(figsize=(6, 4))
            sns.histplot(residuals, bins=50, kde=True)
            plt.title(f"Residuals for {target} for {owner}")
            plt.xlabel("Residual")
            plt.tight_layout()
            plt.show()

    def visualize_metrics(self, results, owner):
        for target, res in results.items():
            metric_names = ["R2 score", "MSE"]
            metric_values = [
                res["r2_score"],
                res["mse"],
            ]

            plt.figure(figsize=(6, 4))
            sns.barplot(x=metric_names, y=metric_values)

            plt.title(f"Model metrics for {target} for {owner}")
            plt.ylabel("Value")
            plt.xlabel("Metric")

            for i, value in enumerate(metric_values):
                plt.text(
                    i,
                    value,
                    f"{value:.4f}",
                    ha="center",
                    va="bottom",
                )

            plt.tight_layout()
            plt.show()

    def visualize_importance_lollipop(self, results, features, owner):
        for target, res in results.items():
            importances = np.asarray(res["feature_importances"], dtype=float)
            feature_names = np.asarray(features)

            sorted_idx = np.argsort(importances)
            sorted_importances = importances[sorted_idx]
            sorted_features = feature_names[sorted_idx]

            positions = np.arange(len(sorted_features))

            fig, ax = plt.subplots(figsize=(10, 7))

            ax.hlines(
                y=positions,
                xmin=0,
                xmax=sorted_importances,
                linewidth=1.5,
                alpha=0.7,
            )

            ax.scatter(
                sorted_importances,
                positions,
                s=70,
                zorder=3,
            )

            for position, importance in zip(positions, sorted_importances):
                ax.text(
                    importance,
                    position,
                    f"  {importance:.4f}",
                    va="center",
                    fontsize=8,
                )

            ax.set_yticks(positions)
            ax.set_yticklabels(sorted_features)
            ax.set_xlabel("Feature importance")
            ax.set_ylabel("Feature")
            ax.set_title(
                f"Random forest feature importance for {owner}"
            )

            upper_limit = (
                sorted_importances.max() * 1.18
                if sorted_importances.max() > 0
                else 1
            )
            ax.set_xlim(0, upper_limit)
            ax.grid(axis="x", alpha=0.25)

            fig.tight_layout()
            plt.show()

    def visualize_prediction_fit_hexbin(self, results, owner):
        for target, res in results.items():
            y_true = np.asarray(res["y_true"], dtype=float)
            y_pred = np.asarray(res["y_pred"], dtype=float)

            valid_mask = np.isfinite(y_true) & np.isfinite(y_pred)
            y_true = y_true[valid_mask]
            y_pred = y_pred[valid_mask]

            lower = min(y_true.min(), y_pred.min())
            upper = max(y_true.max(), y_pred.max())

            fig, ax = plt.subplots(figsize=(7, 6))

            density_plot = ax.hexbin(
                y_true,
                y_pred,
                gridsize=45,
                mincnt=1,
                bins="log",
                linewidths=0.2,
            )

            ax.plot(
                [lower, upper],
                [lower, upper],
                linestyle="--",
                linewidth=1.5,
                label="Perfect prediction",
            )

            ax.set_xlim(lower, upper)
            ax.set_ylim(lower, upper)
            ax.set_aspect("equal", adjustable="box")

            ax.set_xlabel("Observed log PR review hours")
            ax.set_ylabel("Predicted log PR review hours")
            ax.set_title(
                f"Observed versus predicted review time for {owner}\n"
                f"R² = {res['r2_score']:.3f}, "
                f"MSE = {res['mse']:.3f}"
            )

            colorbar = fig.colorbar(density_plot, ax=ax)
            colorbar.set_label("Observation density")

            ax.legend()
            fig.tight_layout()
            plt.show()

#TODO new
    def visualize_importance_treemap(self, results, features, owner):
        """
        Publication-friendly feature-importance treemap.

        - Major features are shown in the main treemap.
        - Minor features are shown in a separately rescaled treemap.
        - The table preserves every exact importance value.
        """
        import matplotlib.pyplot as plt
        import matplotlib.patches as patches
        import numpy as np
        import squarify

        for target, res in results.items():
            importances = np.asarray(
                res["feature_importances"],
                dtype=float,
            )
            feature_names = np.asarray(features)

            sorted_idx = np.argsort(importances)[::-1]
            sorted_importances = importances[sorted_idx]
            sorted_features = feature_names[sorted_idx]

            ranks = np.arange(1, len(sorted_features) + 1)

            # Zero-importance features remain in the table only.
            positive_mask = sorted_importances > 0

            positive_importances = sorted_importances[positive_mask]
            positive_features = sorted_features[positive_mask]
            positive_ranks = ranks[positive_mask]

            # First nine features in the main panel.
            split_index = min(9, len(positive_importances))

            major_importances = positive_importances[:split_index]
            major_features = positive_features[:split_index]
            major_ranks = positive_ranks[:split_index]

            minor_importances = positive_importances[split_index:]
            minor_features = positive_features[split_index:]
            minor_ranks = positive_ranks[split_index:]

            figure = plt.figure(
                figsize=(19, 10),
                dpi=160,
                constrained_layout=True,
            )

            grid = figure.add_gridspec(
                nrows=2,
                ncols=2,
                width_ratios=[2.6, 1.7],
                height_ratios=[3.4, 1.25],
            )

            major_axis = figure.add_subplot(grid[0, 0])
            minor_axis = figure.add_subplot(grid[1, 0])
            table_axis = figure.add_subplot(grid[:, 1])

            def draw_treemap(
                    axis,
                    values,
                    feature_subset,
                    rank_subset,
                    title,
                    minimum_font_size,
            ):
                if len(values) == 0:
                    axis.axis("off")
                    return

                normalized_sizes = squarify.normalize_sizes(
                    values,
                    100,
                    100,
                )

                rectangles = squarify.squarify(
                    normalized_sizes,
                    x=0,
                    y=0,
                    dx=100,
                    dy=100,
                )

                colors = plt.cm.viridis(
                    np.linspace(0.15, 0.90, len(rectangles))
                )

                for rectangle, importance, feature, rank, color in zip(
                        rectangles,
                        values,
                        feature_subset,
                        rank_subset,
                        colors,
                ):
                    x = rectangle["x"]
                    y = rectangle["y"]
                    width = rectangle["dx"]
                    height = rectangle["dy"]
                    area = width * height

                    patch = patches.Rectangle(
                        (x, y),
                        width,
                        height,
                        facecolor=color,
                        edgecolor="white",
                        linewidth=2.5,
                    )
                    axis.add_patch(patch)

                    # Major rectangles show rank and exact importance.
                    if area >= 250 and width >= 10 and height >= 8:
                        label = f"F{rank}\n{importance:.4f}"
                        font_size = min(
                            17,
                            max(
                                minimum_font_size,
                                7 + np.sqrt(area) * 0.18,
                            ),
                        )
                    else:
                        label = f"F{rank}\n{importance:.4f}"
                        font_size = minimum_font_size

                    axis.text(
                        x + width / 2,
                        y + height / 2,
                        label,
                        ha="center",
                        va="center",
                        fontsize=font_size,
                        fontweight="semibold",
                        clip_on=True,
                    )

                axis.set_xlim(0, 100)
                axis.set_ylim(0, 100)
                axis.set_aspect("equal")
                axis.axis("off")
                axis.set_title(
                    title,
                    fontsize=15,
                    pad=10,
                )

            draw_treemap(
                axis=major_axis,
                values=major_importances,
                feature_subset=major_features,
                rank_subset=major_ranks,
                title=f"Dominant feature importances for {owner}",
                minimum_font_size=10,
            )

            draw_treemap(
                axis=minor_axis,
                values=minor_importances,
                feature_subset=minor_features,
                rank_subset=minor_ranks,
                title="Minor feature importances — independently rescaled",
                minimum_font_size=10,
            )

            # Exact-value table.
            table_axis.axis("off")

            table_rows = [
                [
                    f"F{rank}",
                    feature,
                    f"{importance:.4f}",
                ]
                for rank, feature, importance in zip(
                    ranks,
                    sorted_features,
                    sorted_importances,
                )
            ]

            table = table_axis.table(
                cellText=table_rows,
                colLabels=["Rank", "Feature", "Importance"],
                colLoc="left",
                cellLoc="left",
                loc="center",
                colWidths=[0.13, 0.64, 0.23],
            )

            table.auto_set_font_size(False)
            table.set_fontsize(10.5)
            table.scale(1.0, 1.65)

            # Header formatting.
            for column in range(3):
                header_cell = table[0, column]
                header_cell.get_text().set_fontweight("bold")
                header_cell.get_text().set_fontsize(11)

            # Align numeric values to the right.
            for row_number in range(1, len(table_rows) + 1):
                table[row_number, 2].get_text().set_ha("right")

            table_axis.set_title(
                "Exact feature-importance values",
                fontsize=15,
                pad=16,
            )

            figure.suptitle(
                f"Random-forest feature importance: {target}",
                fontsize=18,
                fontweight="semibold",
            )

            plt.show()


    def visualize_prediction_profile(self, results, owner):
        """
        Ordered prediction profile.

        Every original validation value is retained. Observations are sorted
        by the actual target, and the corresponding predictions remain paired
        with their original observations.
        """
        for target, res in results.items():
            y_true = np.asarray(res["y_true"], dtype=float)
            y_pred = np.asarray(res["y_pred"], dtype=float)

            valid_mask = np.isfinite(y_true) & np.isfinite(y_pred)
            y_true = y_true[valid_mask]
            y_pred = y_pred[valid_mask]

            order = np.argsort(y_true)

            ordered_true = y_true[order]
            ordered_pred = y_pred[order]
            observation_rank = np.arange(1, len(ordered_true) + 1)

            fig, ax = plt.subplots(figsize=(12, 6))

            ax.plot(
                observation_rank,
                ordered_true,
                label="Observed",
                linewidth=1.5,
            )

            ax.plot(
                observation_rank,
                ordered_pred,
                label="Predicted",
                linewidth=1.2,
                alpha=0.85,
            )

            ax.set_xlabel("Validation observations ranked by observed value")
            ax.set_ylabel("Log PR review hours")
            ax.set_title(
                f"Ordered prediction profile for {owner}: {target}\n"
                f"R² = {res['r2_score']:.4f}, "
                f"MSE = {res['mse']:.4f}"
            )

            ax.legend()
            ax.grid(axis="y", alpha=0.25)

            fig.tight_layout()
            plt.show()