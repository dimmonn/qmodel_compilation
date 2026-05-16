from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class PsInactivityToIssuesPr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/dag_to_prs.sql',
                                        '../../../persistence/dag_to_prs.sql.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'commit_count',
            'num_of_files_changed',
            'merge_count_in_pr',
            'avg_in_degree',
            'avg_out_degree',
            'avg_max_depth',
            'avg_dist_to_branch_start',
            'max_dist_to_branch_start',
            'avg_upstream_heads_unique',
            'max_upstream_heads_unique'

        ]
        self.targets = ['pr_review_hours']

        self.strategy_name = "pearson_spearman"
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_correlation(features=self.features, targets=self.targets,
                                                     results=correlation_results)

    def visualize_scatter(self):
        self.analysis_strategy._scatterplot_matrix(data=self.data,
                                                   features=self.features,
                                                   targets=self.targets)


def main():
    model = PsInactivityToIssuesPr()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)
    model.visualize_scatter()


if __name__ == "__main__":
    main()
