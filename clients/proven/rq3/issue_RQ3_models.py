import numpy as np
from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class IssueDefectRQ3Models:
    """
    RQ3 (defect side only):

        To what extent can graph and churn metrics of
        bug-introducing commits (that belong to PRs)
        explain issue resolution time?

    SQL:
        ../../../queries/issue_rq3_defect_graph_churn_pr_commits.sql

    One row = one closed issue.
    Only SZZ bug-introducing commits with commit.pr_id > 0 are used.

    Target:
        log_issue_resolution_hours  (log1p of hours, for heavy tails)

    Features:
        All bic_* graph and churn metrics from the SQL above.
    """

    def __init__(self, project_owner: str):
        self.project_owner = project_owner

        data_handler = DataCacheHandler(
            '../../../queries/issue_defect_graph_ci_metrics.sql',
            f'../../../persistence/files/issue_rq3_defect_graph_churn_pr_commits_{project_owner}.parquet',
            project_owner,
        )

        df = data_handler.load_from_parquet()

        df = df[df['project_owner'] == self.project_owner].copy()

        df = df[df['issue_resolution_hours'].notna()].copy()
        df['log_issue_resolution_hours'] = np.log1p(df['issue_resolution_hours'])

        self.data = df

        self.features = [
            "bic_num_commits",
            "bic_avg_depth_diff",
            "bic_max_depth_diff",
            "bic_avg_branch_commit_rate",

            "bic_avg_fp_distance",
            "bic_max_fp_distance",
            "bic_avg_upstream_heads",
            "bic_max_upstream_heads",
            "bic_avg_days_since_merge",
            "bic_max_days_since_merge",
            "bic_avg_in_degree",
            "bic_avg_out_degree",
            "bic_avg_branches",
            "bic_avg_average_degree",
            "bic_total_additions",
            "bic_total_deletions",
            "bic_total_changes",
            "bic_avg_changes_per_file",
            "bic_max_changes_in_file",
            "bic_num_files_changed",
            "bic_change_density_per_file"
        ]

        # ---------- TARGET ----------
        self.targets = ['log_issue_resolution_hours']

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


def main():
    for owner in ["ansible", "facebook"]:
        print(f"\n=== Defect-side RQ3 models for owner = {owner} ===")
        client = IssueDefectRQ3Models(project_owner=owner)
        lin_results = client.run_linear()
        client.visualize_linear(lin_results)
        rf_results = client.run_random_forest()
        client.visualize_random_forest(rf_results)


if __name__ == "__main__":
    main()
