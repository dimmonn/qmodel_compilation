from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class DagToIssuesPrPearsonRQ1:
    """
    RQ1: How do commit-graph metrics relate to issue resolution time?

    One row = one issue × one fixing commit (before grouping).
    The SQL already aggregates graph/CI metrics PER ISSUE.

    Target:
        issue_resolution_hours

    Features:
        Graph metrics, patch size, CI metrics aggregated over fixing commits.
    """

    def __init__(self, project_owner: str):
        self.project_owner = project_owner

        data_handler = DataCacheHandler(
            '../../../queries/issue_defect_graph_ci_metrics.sql',
            f'../../../persistence/files/issue_defect_graph_ci_metrics_{project_owner}.parquet',
            project_owner
        )

        df = data_handler.load_from_parquet()

        df = df[df['project_owner'] == self.project_owner].copy()

        df.fillna(0, inplace=True)

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

        self.targets = ['issue_resolution_hours']

        self.strategy_name = "pearson_spearman"
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)

    def run(self):
        """Run Pearson + Spearman correlation for RQ1."""
        return self.analysis_strategy.analyze(
            data=self.data,
            features=self.features,
            targets=self.targets
        )

    def visualize(self, correlation_results):
        """Visualize correlations."""
        self.analysis_strategy.visualize_correlation(
            features=self.features,
            targets=self.targets,
            results=correlation_results, owner=f'defects for {self.project_owner}'
        )


def main():
    for owner in ["ansible", "facebook"]:
        print(f"\n=== RQ1 bug introduction issues correlations for owner = {owner} ===")
        model = DagToIssuesPrPearsonRQ1(project_owner=owner)
        corr = model.run()
        model.visualize(correlation_results=corr)


if __name__ == "__main__":
    main()
