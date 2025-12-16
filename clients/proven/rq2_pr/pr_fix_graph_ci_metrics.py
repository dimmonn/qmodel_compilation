from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class DagToPrFixPearsonRQ2:
    """
    RQ1 (fix side only):
        How do commit-graph metrics and code churn of *fixing* commits
        relate to issue resolution time?

    SQL source:
        ../../../queries/issue_fix_graph_ci_metrics.sql

    One row = one issue, aggregated over all fixing commits for that issue.

    Target:
        issue_resolution_hours

    Features:
        Graph metrics + code churn metrics for fixing commits.
    """

    def __init__(self, project_owner: str):
        self.project_owner = project_owner
        data_handler = DataCacheHandler(
            '../../../queries/pull_fix_graph_ci_metrics.sql',
            f'../../../persistence/files/pull_fix_graph_ci_metrics_{project_owner}.parquet',
            project_owner,
        )

        df = data_handler.load_from_parquet()

        df = df[df['project_owner'] == self.project_owner].copy()

        self.data = df
        self.features = [
            'fix_num_commits',
            'fix_avg_min_depth',
            'fix_avg_max_depth',
            'fix_avg_fp_distance',
            'fix_max_fp_distance',
            'fix_avg_upstream_heads',
            'fix_max_upstream_heads',
            'fix_avg_days_since_merge',
            'fix_max_days_since_merge',
            'fix_avg_in_degree',
            'fix_avg_out_degree',
            'fix_avg_average_degree',
            'fix_total_additions',
            'fix_total_deletions',
            'fix_total_changes',
            'fix_avg_changes_per_file',
            'fix_max_changes_in_file',
            'fix_num_files_changed',
            'fix_change_density_per_file'
        ]

        self.targets = ['pr_review_hours']

        # Analysis strategy
        self.strategy_name = "pearson_spearman"
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)

    def run(self):
        """Run Pearson + Spearman correlation for RQ1 (fix side)."""
        return self.analysis_strategy.analyze(
            data=self.data,
            features=self.features,
            targets=self.targets,
        )

    def visualize(self, correlation_results):
        """Visualize correlations (heatmaps)."""
        self.analysis_strategy.visualize_correlation(
            features=self.features,
            targets=self.targets,
            results=correlation_results, owner=f'fix for {self.project_owner}'
        )


def main():
    for owner in ["ansible", "facebook"]:
        print(f"\n=== RQ1 fixing pr correlations for owner = {owner} ===")
        model = DagToPrFixPearsonRQ2(project_owner=owner)
        corr = model.run()
        model.visualize(correlation_results=corr)


if __name__ == "__main__":
    main()
