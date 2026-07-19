from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class BidToIssuesAnova:
    def __init__(self):
        data_handler = DataCacheHandler('../../queries/sql_compilation/bug_introduced_defects_to_issues.sql',
                                        '../../persistence/files/bug_introduced_defects_to_issues.parquet')



        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = ['average_degree',
                         'comment_count',
                         'in_degree',
                         'max_depth_of_commit_history',
                         'merge_count',
                         'min_depth_of_commit_history',
                         'num_of_files_changed',
                         'number_of_branches',
                         'number_of_edges',
                         'number_of_vertices',
                         'out_degree'
                         ]
        self.targets = ['fix_time_minutes']
        strategy_name = "anova"
        self.analysis_strategy = AnalysisFactory.get_analysis(strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_anova(features=self.features, results=correlation_results)


def main():
    model = BidToIssuesAnova()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)


if __name__ == "__main__":
    main()
