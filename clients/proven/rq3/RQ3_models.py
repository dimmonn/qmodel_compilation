import numpy as np
from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class IssueDefectRQ3Models:

    def __init__(self, project_owner: str):
        self.project_owner = project_owner

        data_handler = DataCacheHandler(
            '../../../queries/RQ3.sql',
            f'../../../persistence/files/pr_rq3_review_time_graph_churn_ci_bic_{project_owner}.parquet',
            project_owner,
        )

        df = data_handler.load_from_parquet()

        df = df[df['project_owner'] == self.project_owner].copy()

        df = df[df['pr_review_hours'].notna()].copy()
        df['pr_review_hours'] = np.log1p(df['pr_review_hours'])

        self.data = df

        self.features = [
            "pr_label_count",
            "pr_assignee_count",
            "pr_reviewer_count",
            "pr_timeline_event_count",
            "pr_reaction_count",
            "pr_num_commits",
            "pr_graph_ready_commits",
            "pr_churn_ready_commits",
            "pr_ci_ready_commits",
            "pr_contains_candidate_bic",
            "pr_candidate_bic_commits",
            "pr_candidate_bic_issue_links",
            "pr_avg_min_depth",
            "pr_avg_max_depth",
            "pr_avg_depth_diff",
            "pr_max_depth_diff"
        ]

        # ---------- TARGET ----------
        self.targets = ['log_pr_review_hours']

    # ------------------- LINEAR REGRESSION -------------------

    def run_linear(self):
        strategy = AnalysisFactory.get_analysis("linear_regression")
        return strategy.analyze(
            data=self.data,
            features=self.features,
            targets=self.targets,
        )

    def visualize_linear(self, lin_results):
        strategy = AnalysisFactory.get_analysis("linear_regression")
        strategy.visualize_regression(
            results=lin_results,
            features=self.features,
            targets=self.targets,
            owner=self.project_owner,
        )

    def _ensure_dataset_split(self):
        """
        RandomForestAnalysis expects a 'dataset_split' column with values
        'train' / 'validation'. If it's missing, create an 80/20 split.
        """
        if 'dataset_split' not in self.data.columns:
            rng = np.random.default_rng(42)
            mask = rng.random(len(self.data)) < 0.8
            self.data['dataset_split'] = np.where(mask, 'train', 'validation')

    def run_random_forest(self):
        self._ensure_dataset_split()
        strategy = AnalysisFactory.get_analysis("random_forest")
        return strategy.analyze(
            data=self.data,
            features=self.features,
            targets=self.targets,
        )

    def visualize_random_forest(self, rf_results):
        strategy = AnalysisFactory.get_analysis("random_forest")
        strategy.visualize_importance(rf_results, self.features, self.project_owner)
        strategy.visualize_prediction_fit(rf_results, self.project_owner)
        strategy.visualize_residuals(rf_results, self.project_owner)
        strategy.visualize_metrics(rf_results, self.project_owner)
        strategy.visualize_importance_lollipop(results=rf_results, features=self.features, owner=self.project_owner)
        strategy.visualize_prediction_fit_hexbin(results=rf_results, owner=self.project_owner)
        strategy.visualize_importance_treemap(results=rf_results, features=self.features, owner=self.project_owner)
        strategy.visualize_prediction_profile(results=rf_results, owner=self.project_owner)


def main():
    for owner in ["ansible", "facebook"]:
        print(f"\n=== Defect-side RQ3 models for owner = {owner} ===")
        client = IssueDefectRQ3Models(project_owner=owner)
        lin_results = client.run_linear()
        print(lin_results)
        client.visualize_linear(lin_results)
        rf_results = client.run_random_forest()
        client.visualize_random_forest(rf_results)


if __name__ == "__main__":
    main()
