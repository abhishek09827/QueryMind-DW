class ResultExplainer:
    def explain(self, question, sql, df):
        """
        Generates a simple natural language explanation of the results.
        For a production system, this would call the LLM again with the data summary.
        """
        if df is None or df.empty:
            return "No results found for your query."
        
        row_count = len(df)
        columns = ", ".join(df.columns.tolist())
        
        explanation = f"Query executed successfully.\n"
        explanation += f"Question: '{question}'\n"
        explanation += f"Result contains {row_count} rows with columns: {columns}.\n"
        
        # Simple heuristic explanation
        explanation += "\nKey Insights:\n"
        if row_count > 0:
            first_row = df.iloc[0].to_dict()
            explanation += f"- Top result: {first_row}\n"
        
        if row_count > 100:
             explanation += "- Note: Result truncated to 100 rows."

        return explanation
