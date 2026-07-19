from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler
from context.rf_context import RfContext
from strategies.random_forest import RandomForestAnalysis


class RfInactivityToIssuesPr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/sql_compilation/developer_inactivity_to_issues_pr.sql',
                                        '../../../persistence/developer_inactivity_to_issues_pr.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'inactivity_before_issue_minutes',
            'inactivity_before_pull_request_minutes',
        ]
        self.targets = ['issue_resolution_time', 'project_pull_review_time']

        self.strategy_name = "random_forest"
        self.analysis_strategy: RandomForestAnalysis = AnalysisFactory.get_analysis(self.strategy_name)
        self.context = RfContext(self.analysis_strategy, self.data)


def main():
    model = RfInactivityToIssuesPr()
    model.context.run(model.features, model.targets)
    # regression_results = model.run()
    # model.visualize_importance(regression_results=regression_results)
    # model.visualize_prediction_fit(regression_results=regression_results)
    # model.visualize_residuals(regression_results=regression_results)


if __name__ == "__main__":
    main()
