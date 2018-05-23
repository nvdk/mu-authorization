alias Updates.QueryAnalyzer.Iri, as: Iri
alias Updates.QueryAnalyzer.String, as: Str
alias Updates.QueryAnalyzer.Boolean, as: Bool
alias Updates.QueryAnalyzer.NumericLiteral, as: Number
alias Updates.QueryAnalyzer.Variable, as: Var

defprotocol Updates.QueryAnalyzer.P do
  def to_solution_sym( element )
end


defmodule Iri do
  defstruct [:iri, :real_name]

  def from_iri_string( iri, _options \\ [] ) do
    new_iri = String.trim( iri, " " ) # TODO remove trimming when terminal symbols don't emit spaces anymore
    %Iri{ iri: new_iri, real_name: new_iri }
  end

  def from_prefix_string( prefixed_name, %{ prefixes: prefixes, default_graph: %Iri{ iri: default_graph } } ) do
    [ prefix, postfix ] =
      prefixed_name
      |> String.trim( " " ) # TODO remove trimming when terminal symbols don't emit spaces anymore
      |> String.split( ":", parts: 2 )

    base_uri =
      if prefix == "" do
        default_graph
        |> String.trim( " " ) # TODO remove trimming when terminal symbols don't emit spaces anymore
        |> String.slice( 1, String.length( default_graph ) - 2 )
      else
        %Iri{ iri: iri } = Map.get( prefixes, prefix )
        strip_iri_marks( iri )
      end

    full_iri = "<" <> base_uri <> postfix <> ">"
    %Iri{ iri: full_iri, real_name: prefixed_name }
  end

  def make_a do
    %Iri{ iri: "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>", real_name: "a" }
  end

  def is_a?( %Iri{ iri: iri } ) do
    iri == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"
  end

  defp strip_iri_marks( string ) do
    String.slice( string, 1, String.length( string ) - 2 )
  end

  defimpl Updates.QueryAnalyzer.P do
    def to_solution_sym( %Iri{ iri: full_name } ) do
      # TODO: Emit values the way we received them
      %InterpreterTerms.SymbolMatch{
        symbol: :iri,
        submatches: [
          %InterpreterTerms.SymbolMatch{
            symbol: :IRIREF,
            string: full_name,
            submatches: :none } ] }
    end
  end
end

defmodule Var do
  defstruct [:full_name]

  def from_string( value ) do
    %Var{ full_name: value }
  end

  def is_var( %Var{} ) do
    true
  end

  def is_var( _ ) do
    false
  end

  @doc """
  Returns the name of the variable without its prefix.

      iex> Updates.QueryAnalyzer.Variable.pure_name( %Updates.QueryAnalyzer.Variable{ full_name: "?foo" } )
      > "foo"
  """
  def pure_name( %Var{ full_name: full_name } ) do
    { _, pure_name } = String.next_grapheme( full_name )
    pure_name
  end

  defimpl Updates.QueryAnalyzer.P do
    def to_solution_sym( %Var{} = var ) do
      Var.to_solution_sym( var )
    end
  end

  def to_solution_sym( %Var{ full_name: full_name } ) do
    symbol =
      case full_name do
        << "?", _ :: binary >> -> :VAR1
        << "$", _ :: binary >> -> :VAR2
      end

    %InterpreterTerms.SymbolMatch{
      symbol: :Var,
      submatches: [
        %InterpreterTerms.SymbolMatch{
          symbol: symbol,
          string: full_name,
          submatches: :none
        }
      ]
    }
  end
end

defmodule Bool do
  defstruct [:value]

  def from_string( value ) do
    bool = case String.downcase( value ) do
             'true' -> true
             'false' -> false
           end

    %Bool{ value: bool }
  end
  def from_boolean( boolean ) when is_boolean( boolean ) do
    %Bool{ value: boolean }
  end

  defimpl Updates.QueryAnalyzer.P do
    def to_solution_sym( %Bool{ value: value } ) do
      word = if value do
        "true"
      else
        "false"
      end

      %InterpreterTerms.SymbolMatch{
        symbol: :RDFLiteral,
        submatches: [
          %InterpreterTerms.SymbolMatch{
            symbol: :BooleanLiteral,
            submatches: [
              %InterpreterTerms.WordMatch{
                word: word } ] } ] }
    end
  end
end

defmodule Str do
  defstruct [:str, {:lang, false}, {:type, false}]

  def from_string( string ) do
    %Str{ str: string }
  end
  def from_langstring( string, language ) do
    %Str{ str: string, lang: language }
  end
  def from_typestring( string, type ) do
    %Str{ str: string, type: type }
  end

  defimpl Updates.QueryAnalyzer.P do
    def to_solution_sym( %Str{ str: string, lang: lang, type: type } = str ) do
      case str do
        %Str{ lang: false, type: false } ->
          # it is a simple string
          %InterpreterTerms.SymbolMatch{
            symbol: :RDFLiteral,
            submatches: [
            %InterpreterTerms.SymbolMatch{
              symbol: :String,
              submatches: [
                %InterpreterTerms.SymbolMatch{
                  symbol: :STRING_LITERAL2,
                  string: string,
                  submatches: :none } ] } ] }
        %Str{ lang: false } ->
          # it is a typed string
          %InterpreterTerms.SymbolMatch{
            symbol: :RDFLiteral,
            submatches: [
              %InterpreterTerms.SymbolMatch{
                symbol: :String,
                submatches: [
                  %InterpreterTerms.SymbolMatch{
                    symbol: :STRING_LITERAL2,
                    string: string,
                    submatches: :none } ] },
              %InterpreterTerms.WordMatch{ word: "^^" },
              Updates.QueryAnalyzer.P.to_solution_sym( type ) ] }
        %Str{ type: false } ->
          # it is a language typed string
          %InterpreterTerms.SymbolMatch{
            symbol: :RDFLiteral,
            submatches: [
              %InterpreterTerms.SymbolMatch{
                symbol: :String,
                submatches: [
                  %InterpreterTerms.SymbolMatch{
                    symbol: :STRING_LITERAL2,
                    string: string,
                    submatches: :none } ] },
              %InterpreterTerms.SymbolMatch{
                symbol: :LANGTAG,
                string: "@" <> lang,
                submatches: :none } ] }
      end
    end
  end
end

defmodule Number do
  defstruct [ :str ]

  def from_string( string ) do
    %Str{ str: string }
  end

  defimpl Updates.QueryAnalyzer.P do
    def to_solution_sym( %Number{ str: str } ) do
      # TODO this does not necessarily emit the correct structure, yet
      # it will yield the correct SPARQL query.
      
      %InterpreterTerms.SymbolMatch{
        symbol: :RDFLiteral,
        submatches: [
          %InterpreterTerms.SymbolMatch{
            symbol: :NumericLiteral,
            submatches: [
              %InterpreterTerms.SymbolMatch{
                symbol: :NumericLiteralUnsigned,
                submatches: [
                  %InterpreterTerms.SymbolMatch{
                    symbol: :DECIMAL,
                    string: str,
                    submatches: :none } ] } ] } ] }
    end
  end
end
  
