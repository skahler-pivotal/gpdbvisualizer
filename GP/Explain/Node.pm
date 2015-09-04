package GP::Explain::Node;
use strict;
use Clone qw( clone );
use HOP::Lexer qw( string_lexer );
use Carp;
use warnings;
use strict;

=head1 NAME

GP::Explain::Node - Class representing single node from query plan

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use GP::Explain::Node;

    my $foo = GP::Explain::Node->new();
    ...

=head1 FUNCTIONS

=head2 actual_loops

Returns number how many times current node has been executed.

This information is available only when parsing EXPLAIN ANALYZE output - not in EXPLAIN output.

=head2 actual_rows

Returns amount of rows current node returnes in single execution (i.e. if given node was executed 10 times, you have to multiply actual_rows by 10, to get full number of returned rows.

This information is available only when parsing EXPLAIN ANALYZE output - not in EXPLAIN output.

=head2 actual_time_first

Returns time (in miliseconds) how long it took PostgreSQL to return 1st row from given node.

This information is available only when parsing EXPLAIN ANALYZE output - not in EXPLAIN output.

=head2 actual_time_last

Returns time (in miliseconds) how long it took PostgreSQL to return all rows from given node. This number represents single execution of the node, so if given node was executed 10 times, you have to multiply actual_time_last by 10 to get total time of running of this node.

This information is available only when parsing EXPLAIN ANALYZE output - not in EXPLAIN output.

=head2 estimated_rows

Returns estimated number of rows to be returned from this node.

=head2 estimated_row_width

Returns estimated width (in bytes) of single row returned from this node.

=head2 estimated_startup_cost

Returns estimated cost of starting execution of given node. Some node types do not have startup cost (i.e., it is 0), but some do. For example - Seq Scan has startup cost = 0, but Sort node has
startup cost depending on number of rows.

This cost is measured in units of "single-page seq scan".

=head2 estimated_total_cost

Returns estimated full cost of given node. 

This cost is measured in units of "single-page seq scan".

=head2 type

Textual representation of type of current node. Some types for example:

=over

=item * Index Scan

=item * Index Scan Backward

=item * Limit

=item * Nested Loop

=item * Nested Loop Left Join

=item * Result

=item * Seq Scan

=item * Sort

=back

=head2 scan_on

Hashref with extra information in case of table scans.

For Seq Scan it contains always 'table_name' key, and optionally 'table_alias' key.

For Index Scan and Backward Index Scan, it also contains (always) 'index_name' key.

=head2 extra_info

ArrayRef of strings, each contains textual information (leading and tailing spaces removed) for given node.

This is not always filled, as it depends heavily on node type and PostgreSQL version.

=head2 sub_nodes

ArrayRef of GP::Explain::Node objects, which represent sub nodes.

For more details, check ->add_sub_node method description.

=head2 initplans

ArrayRef of GP::Explain::Node objects, which represent init plan.

For more details, check ->add_initplan method description.

=head2 subplans

ArrayRef of GP::Explain::Node objects, which represent sub plan.

For more details, check ->add_subplan method description.

=head2 ctes

HashRef of GP::Explain::Node objects, which represent CTE plans.

For more details, check ->add_cte method description.

=head2 cte_order

ArrayRef of names of CTE nodes in given node.

For more details, check ->add_cte method description.

=head2 never_executed

Returns true if given node was not executed, according to plan.

=cut

sub actual_loops           { my $self = shift; $self->{ 'actual_loops' }           = $_[ 0 ] if 0 < scalar @_; return $self->{ 'actual_loops' }; }
sub actual_rows            { my $self = shift; $self->{ 'actual_rows' }            = $_[ 0 ] if 0 < scalar @_; return $self->{ 'actual_rows' }; }
sub actual_time_first      { my $self = shift; $self->{ 'actual_time_first' }      = $_[ 0 ] if 0 < scalar @_; return $self->{ 'actual_time_first' }; }
sub actual_time_last       { my $self = shift; $self->{ 'actual_time_last' }       = $_[ 0 ] if 0 < scalar @_; return $self->{ 'actual_time_last' }; }
sub estimated_rows         { my $self = shift; $self->{ 'estimated_rows' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'estimated_rows' }; }
sub estimated_row_width    { my $self = shift; $self->{ 'estimated_row_width' }    = $_[ 0 ] if 0 < scalar @_; return $self->{ 'estimated_row_width' }; }
sub estimated_startup_cost { my $self = shift; $self->{ 'estimated_startup_cost' } = $_[ 0 ] if 0 < scalar @_; return $self->{ 'estimated_startup_cost' }; }
sub estimated_total_cost   { my $self = shift; $self->{ 'estimated_total_cost' }   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'estimated_total_cost' }; }
sub extra_info             { my $self = shift; $self->{ 'extra_info' }             = $_[ 0 ] if 0 < scalar @_; return $self->{ 'extra_info' }; }
sub initplans              { my $self = shift; $self->{ 'initplans' }              = $_[ 0 ] if 0 < scalar @_; return $self->{ 'initplans' }; }
sub never_executed         { my $self = shift; $self->{ 'never_executed' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'never_executed' }; }
sub scan_on                { my $self = shift; $self->{ 'scan_on' }                = $_[ 0 ] if 0 < scalar @_; return $self->{ 'scan_on' }; }
sub sub_nodes              { my $self = shift; $self->{ 'sub_nodes' }              = $_[ 0 ] if 0 < scalar @_; return $self->{ 'sub_nodes' }; }
sub subplans               { my $self = shift; $self->{ 'subplans' }               = $_[ 0 ] if 0 < scalar @_; return $self->{ 'subplans' }; }
sub type                   { my $self = shift; $self->{ 'type' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'type' }; }
sub ctes                   { my $self = shift; $self->{ 'ctes' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'ctes' }; }
sub cte_order              { my $self = shift; $self->{ 'cte_order' }              = $_[ 0 ] if 0 < scalar @_; return $self->{ 'cte_order' }; }

sub table_name                   { my $self = shift; $self->{ 'table_name' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'table_name' }; }
sub table_alias                   { my $self = shift; $self->{ 'table_alias' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'table_alias' }; }
sub index_name                   { my $self = shift; $self->{ 'index_name' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'index_name' }; }
sub cte_name                   { my $self = shift; $self->{ 'cte_name' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'cte_name' }; }
sub cte_alias                   { my $self = shift; $self->{ 'cte_alias' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'cte_alias' }; }
sub function_name                   { my $self = shift; $self->{ 'function_name' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'function_name' }; }
sub function_alias                   { my $self = shift; $self->{ 'function_alias' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'function_alias' }; }
sub source_segments                   { my $self = shift; $self->{ 'source_segments' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'source_segments' }; }
sub destination_segments                   { my $self = shift; $self->{ 'destination_segments' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'destination_segments' }; }
sub slice                   { my $self = shift; $self->{ 'slice' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'slice' }; }
sub slice_segments                   { my $self = shift; $self->{ 'slice_segments' }                   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'slice_segments' }; }

sub rows_out_avg_rows      { my $self = shift; $self->{ 'rows_out_avg_rows' }      = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_avg_rows' }; }
sub rows_out_workers       { my $self = shift; $self->{ 'rows_out_workers' }       = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_workers' }; }
sub rows_out_count         { my $self = shift; $self->{ 'rows_out_count' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_count' }; }
sub rows_out_max_rows      { my $self = shift; $self->{ 'rows_out_max_rows' }      = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_max_rows' }; }
sub rows_out_max_rows_segment  { my $self = shift; $self->{ 'rows_out_max_rows_segment' }  = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_max_rows_segment' }; }
sub rows_out_ms_to_first_row   { my $self = shift; $self->{ 'rows_out_ms_to_first_row' }   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_ms_to_first_row' }; }
sub rows_out_ms_to_end     { my $self = shift; $self->{ 'rows_out_ms_to_end' }      = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_ms_to_end' }; }
sub rows_out_offset        { my $self = shift; $self->{ 'rows_out_offset' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_out_offset' }; }
sub rows_in_avg_rows       { my $self = shift; $self->{'rows_in_avg_rows' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_in_avg_rows' }; }
sub rows_in_workers       { my $self = shift; $self->{'rows_in_workers' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_in_workers' }; }
sub rows_in_max_rows       { my $self = shift; $self->{'rows_in_max_rows' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_in_max_rows' }; }
sub rows_in_max_rows_segment       { my $self = shift; $self->{'rows_in_max_rows_segment' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_in_max_rows_segment' }; }
sub rows_in_ms_to_end       { my $self = shift; $self->{'rows_in_ms_to_end' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_in_ms_to_end' }; }
sub rows_in_offset       { my $self = shift; $self->{'rows_in_offset' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'rows_in_offset' }; }
sub work_mem_bytes_avg       { my $self = shift; $self->{'work_mem_bytes_avg' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'work_mem_bytes_avg' }; }
sub work_mem_bytes_max       { my $self = shift; $self->{'work_mem_bytes_max' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'work_mem_bytes_max' }; }
sub work_mem_bytes_max_segment       { my $self = shift; $self->{'work_mem_bytes_max_segment' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'work_mem_bytes_max_segment' }; }
sub workfile_number_spilling       { my $self = shift; $self->{'workfile_number_spilling' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'workfile_number_spilling' }; }
sub workfile_number_reused       { my $self = shift; $self->{'workfile_number_reused' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'workfile_number_reused' }; }
sub executor_bytes_avg       { my $self = shift; $self->{'executor_bytes_avg' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'executor_bytes_avg' }; }
sub executor_bytes_max       { my $self = shift; $self->{'executor_bytes_max' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'executor_bytes_max' }; }
sub executor_bytes_max_segment       { my $self = shift; $self->{'executor_bytes_max_segment' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'executor_bytes_max_segment' }; }
sub hash_condition       { my $self = shift; $self->{'hash_condition' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'hash_condition' }; }
sub index_condition       { my $self = shift; $self->{'index_condition' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'index_condition' }; }
sub hash_key       { my $self = shift; $self->{'hash_key' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'hash_key' }; }
sub merge_key       { my $self = shift; $self->{'merge_key' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'merge_key' }; }
sub filter       { my $self = shift; $self->{'filter' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'filter' }; }
sub group_by       { my $self = shift; $self->{'group_by' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'group_by' }; }
sub sort_key_limit       { my $self = shift; $self->{'sort_key_limit' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'sort_key_limit' }; }
sub sort_key_distinct       { my $self = shift; $self->{'sort_key_distinct' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'sort_key_distinct' }; }
sub sort_key       { my $self = shift; $self->{'sort_key' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'sort_key' }; }
sub hash_chain_length_avg       { my $self = shift; $self->{'hash_chain_length_avg' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'hash_chain_length_avg' }; }
sub hash_chain_length_max       { my $self = shift; $self->{'hash_chain_length_max' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'hash_chain_length_max' }; }
sub hash_chain_buckets       { my $self = shift; $self->{'hash_chain_buckets' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'hash_chain_buckets' }; }
sub hash_chain_buckets_used        { my $self = shift; $self->{'hash_chain_buckets_used ' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'hash_chain_buckets_used ' }; }

=head2 new

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args;
    if ( 0 == scalar @_ ) {
        croak( 'Args should be passed as either hash or hashref' );
    }
    if ( 1 == scalar @_ ) {
        if ( 'HASH' eq ref $_[ 0 ] ) {
            %args = @{ $_[ 0 ] };
        }
        else {
            croak( 'Args should be passed as either hash or hashref' );
        }
    }
    elsif ( 1 == ( scalar( @_ ) % 2 ) ) {
        croak( 'Args should be passed as either hash or hashref' );
    }
    else {
        %args = @_;
    }

    @{ $self }{ keys %args } = values %args;

    croak( 'estimated_rows has to be passed to constructor of explain node' )         unless defined $self->estimated_rows;
    croak( 'estimated_row_width has to be passed to constructor of explain node' )    unless defined $self->estimated_row_width;
    croak( 'estimated_startup_cost has to be passed to constructor of explain node' ) unless defined $self->estimated_startup_cost;
    croak( 'estimated_total_cost has to be passed to constructor of explain node' )   unless defined $self->estimated_total_cost;
    croak( 'type has to be passed to constructor of explain node' )                   unless defined $self->type;

    if ( $self->type =~ m{ \A ( Seq \s Scan | Bitmap \s+ Heap \s+ Scan | Append-only \s+ Scan | Foreign \s+ Scan | Update | Insert | Delete ) \s on \s (\S+) (?: \s+ (\S+) ) ? \z }xms ) {
        $self->type( $1 );
        $self->table_name( $2 );
        $self->table_alias( $3 ) if defined $3;
    }
    elsif ( $self->type =~ m{ \A ( Bitmap \s+ Index \s+ Scan) \s on \s (\S+) \z }xms ) {
        $self->type( $1 );
        $self->index_name( $2 );
    }
    elsif ( $self->type =~ m{ \A ( Redistribute \s+ Motion | Broadcast \s+ Motion | Gather \s+ Motion ) \s+ (\S+?) \: (\S+?) \s+ \( slice (\S+?) \; \s segments \: \s+ (\S+) \) \z }xms ) {
        $self->type( $1 );
        $self->source_segments( $2 );
        $self->destination_segments( $3 );
        $self->slice( $4 );
        $self->slice_segments( $5 );
    }
    elsif ( $self->type =~ m{ \A (Index (?: \s Only )? \s Scan (?: \s Backward )? ) \s using \s (\S+) \s on \s (\S+) (?: \s+ (\S+) ) ? \z }xms ) {
        $self->type( $1 );
        $self->index_name( $2 );
        $self->table_name( $3 );
        $self->table_alias( $4 ) if defined $4;
    }
    elsif ( $self->type =~ m{ \A ( CTE \s Scan ) \s on \s (\S+) (?: \s+ (\S+) ) ? \z }xms ) {
        $self->type( $1 );
        $self->cte_name( $2 );
        $self->cte_alias( $3 ) if defined $3;
    }
    elsif ( $self->type =~ m{ \A ( Function \s Scan ) \s on \s (\S+) (?: \s+ (\S+) )? \z }xms ) {
        $self->type( $1 );
        $self->function_name( $2 );
        $self->function_alias( $3 ) if defined $3;
    }
    return $self;
}

=head2 add_additional_info

Adds additional values

=cut

sub add_additional_info {
  my $self = shift;

  my %args;
  if ( 0 == scalar @_ ) {
      croak( 'Args should be passed as either hash or hashref' );
  }
  if ( 1 == scalar @_ ) {
      if ( 'HASH' eq ref $_[ 0 ] ) {
          %args = @{ $_[ 0 ] };
      }
      else {
          croak( 'Args should be passed as either hash or hashref' );
      }
  }
  elsif ( 1 == ( scalar( @_ ) % 2 ) ) {
      croak( 'Args should be passed as either hash or hashref' );
  }
  else {
      %args = @_;
  }

  @{ $self }{ keys %args } = values %args;
  return;
  }

=head2 add_extra_info

Adds new line of extra information to explain node.

It will be available at $node->extra_info (returns arrayref)

Extra_info is used by some nodes to provide additional information. For example
- for Sort nodes, they usually contain informtion about used memory, used sort
method and keys.

=cut

sub add_extra_info {
    my $self = shift;
    if ( $self->extra_info ) {
        push @{ $self->extra_info }, @_;
    }
    else {
        $self->extra_info( [ @_ ] );
    }
    return;
}

=head2 add_subplan

Adds new subplan node.

It will be available at $node->subplans (returns arrayref)

Example of plan with subplan:

 # explain select *, (select oid::int4 from pg_class c2 where c2.relname = c.relname) - oid::int4 from pg_class c;
                                               QUERY PLAN
 ------------------------------------------------------------------------------------------------------
  Seq Scan on pg_class c  (cost=0.00..1885.60 rows=227 width=200)
    SubPlan
      ->  Index Scan using pg_class_relname_nsp_index on pg_class c2  (cost=0.00..8.27 rows=1 width=4)
            Index Cond: (relname = $0)
 (4 rows)


=cut

sub add_subplan {
    my $self = shift;
    if ( $self->subplans ) {
        push @{ $self->subplans }, @_;
    }
    else {
        $self->subplans( [ @_ ] );
    }
    return;
}

=head2 add_initplan

Adds new initplan node.

It will be available at $node->initplans (returns arrayref)

Example of plan with initplan:

 # explain analyze select 1 = (select 1);
                                          QUERY PLAN
 --------------------------------------------------------------------------------------------
  Result  (cost=0.01..0.02 rows=1 width=0) (actual time=0.033..0.035 rows=1 loops=1)
    InitPlan
      ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.003..0.005 rows=1 loops=1)
  Total runtime: 0.234 ms
 (4 rows)

=cut

sub add_initplan {
    my $self = shift;
    if ( $self->initplans ) {
        push @{ $self->initplans }, @_;
    }
    else {
        $self->initplans( [ @_ ] );
    }
    return;
}

=head2 add_cte

Adds new cte node. CTE has to be named, so this function requires 2 arguments: name, and cte object itself.

It will be available at $node->cte( name ), or $node->ctes (returns hashref).

Since we need order (ctes are stored unordered, in hash), there is also $node->cte_order() which returns arrayref of names.

=cut

sub add_cte {
    my $self = shift;
    my ( $name, $cte ) = @_;
    if ( $self->ctes ) {
        $self->ctes->{ $name } = $cte;
        push @{ $self->cte_order }, $name;
    }
    else {
        $self->ctes( { $name => $cte } );
        $self->cte_order( [ $name ] );
    }
    return;
}

=head2 cte

Returns CTE object that has given name.

=cut

sub cte {
    my $self = shift;
    my $name = shift;
    return $self->ctes->{ $name };
}

=head2 add_sub_node

Adds new sub node.

It will be available at $node->sub_nodes (returns arrayref)

Sub nodes are nodes that are used by given node as data sources.

For example - "Join" node, has 2 sources (sub_nodes), which are table scans (Seq Scan, Index Scan or Backward Index Scan) over some tables.

Example plan which contains subnode:

 # explain select * from test limit 1;
                           QUERY PLAN
 --------------------------------------------------------------
  Limit  (cost=0.00..0.01 rows=1 width=4)
    ->  Seq Scan on test  (cost=0.00..14.00 rows=1000 width=4)
 (2 rows)

Node 'Limit' has 1 sub_plan, which is "Seq Scan"

=cut

sub add_sub_node {
    my $self = shift;
    if ( $self->sub_nodes ) {
        push @{ $self->sub_nodes }, @_;
    }
    else {
        $self->sub_nodes( [ @_ ] );
    }
    return;
}

=head2 get_struct

Function which returns simple, not blessed, hashref with all information about given explain node and it's children.

This can be used for debug purposes, or as a base to print information to user.

Output looks like this:

 {
     'estimated_rows'         => '10000',
     'estimated_row_width'    => '148',
     'estimated_startup_cost' => '0',
     'estimated_total_cost'   => '333',
     'scan_on'                => { 'table_name' => 'tenk1', },
     'type'                   => 'Seq Scan',
 }

=cut

sub get_struct {
    my $self  = shift;
    my $reply = {};

    $reply->{ 'estimated_row_width' }    = $self->estimated_row_width        if defined $self->estimated_row_width;
    $reply->{ 'estimated_rows' }         = $self->estimated_rows             if defined $self->estimated_rows;
    $reply->{ 'estimated_startup_cost' } = 0 + $self->estimated_startup_cost if defined $self->estimated_startup_cost;    # "0+" to remove .00 in case of integers
    $reply->{ 'estimated_total_cost' }   = 0 + $self->estimated_total_cost   if defined $self->estimated_total_cost;      # "0+" to remove .00 in case of integers
    $reply->{ 'actual_loops' }           = $self->actual_loops               if defined $self->actual_loops;
    $reply->{ 'actual_rows' }            = $self->actual_rows                if defined $self->actual_rows;
    $reply->{ 'actual_time_first' }      = 0 + $self->actual_time_first      if defined $self->actual_time_first;         # "0+" to remove .00 in case of integers
    $reply->{ 'actual_time_last' }       = 0 + $self->actual_time_last       if defined $self->actual_time_last;          # "0+" to remove .00 in case of integers
    $reply->{ 'type' }                   = $self->type                       if defined $self->type;
    $reply->{ 'scan_on' }                = clone( $self->scan_on )           if defined $self->scan_on;
    $reply->{ 'extra_info' }             = clone( $self->extra_info )        if defined $self->extra_info;
    $reply->{ 'table_name' }                   = $self->table_name                       if defined $self->table_name;
    $reply->{ 'table_alias' }                   = $self->table_alias                       if defined $self->table_alias;
    $reply->{ 'index_name' }                   = $self->index_name                       if defined $self->index_name;
    $reply->{ 'cte_name' }                   = $self->cte_name                       if defined $self->cte_name;
    $reply->{ 'cte_alias' }                   = $self->cte_alias                       if defined $self->cte_alias;
    $reply->{ 'function_name' }                   = $self->function_name                       if defined $self->function_name;
    $reply->{ 'function_alias' }                   = $self->function_alias                       if defined $self->function_alias;
    $reply->{ 'source_segments' }                   = $self->source_segments                       if defined $self->source_segments;
    $reply->{ 'destination_segments' }                   = $self->destination_segments                       if defined $self->destination_segments;
    $reply->{ 'slice' }                   = $self->slice                       if defined $self->slice;
    $reply->{ 'slice_segments' }                   = $self->slice_segments                       if defined $self->slice_segments;

    $reply->{ 'rows_out_avg_rows' }            = $self->rows_out_avg_rows               if defined $self->rows_out_avg_rows;
    $reply->{ 'rows_out_workers' }            = $self->rows_out_workers               if defined $self->rows_out_workers;
    $reply->{ 'rows_out_count' }            = $self->rows_out_count               if defined $self->rows_out_count;
    $reply->{ 'rows_out_max_rows' }            = $self->rows_out_max_rows               if defined $self->rows_out_max_rows;
    $reply->{ 'rows_out_max_rows_segment' }            = $self->rows_out_max_rows_segment               if defined $self->rows_out_max_rows_segment;
    $reply->{ 'rows_out_ms_to_first_row' }            = $self->rows_out_ms_to_first_row               if defined $self->rows_out_ms_to_first_row;
    $reply->{ 'rows_out_ms_to_end' }            = $self->rows_out_ms_to_end               if defined $self->rows_out_ms_to_end;
    $reply->{ 'rows_out_offset' }            = $self->rows_out_offset               if defined $self->rows_out_offset;
    $reply->{ 'rows_in_avg_rows' }            = $self->rows_in_avg_rows               if defined $self->rows_in_avg_rows;
    $reply->{ 'rows_in_workers' }            = $self->rows_in_workers               if defined $self->rows_in_workers;
    $reply->{ 'rows_in_max_rows' }            = $self->rows_in_max_rows               if defined $self->rows_in_max_rows;
    $reply->{ 'rows_in_max_rows_segment' }            = $self->rows_in_max_rows_segment               if defined $self->rows_in_max_rows_segment;
    $reply->{ 'rows_in_ms_to_end' }            = $self->rows_in_ms_to_end               if defined $self->rows_in_ms_to_end;
    $reply->{ 'rows_in_offset' }            = $self->rows_in_offset               if defined $self->rows_in_offset;
    $reply->{ 'work_mem_bytes_avg' }            = $self->work_mem_bytes_avg              if defined $self->work_mem_bytes_avg;
    $reply->{ 'work_mem_bytes_max' }            = $self->work_mem_bytes_max              if defined $self->work_mem_bytes_max;
    $reply->{ 'work_mem_bytes_max_segment' }            = $self->work_mem_bytes_max_segment              if defined $self->work_mem_bytes_max_segment;
    $reply->{ 'workfile_number_spilling' }            = $self->workfile_number_spilling              if defined $self->workfile_number_spilling;
    $reply->{ 'workfile_number_reused' }            = $self->workfile_number_reused              if defined $self->workfile_number_reused;
    $reply->{ 'executor_bytes_avg' }            = $self->executor_bytes_avg              if defined $self->executor_bytes_avg;
    $reply->{ 'executor_bytes_max' }            = $self->executor_bytes_max              if defined $self->executor_bytes_max;
    $reply->{ 'executor_bytes_max_segment' }            = $self->executor_bytes_max_segment              if defined $self->executor_bytes_max_segment;
    $reply->{ 'hash_condition' }            = $self->hash_condition              if defined $self->hash_condition;
    $reply->{ 'index_condition' }            = $self->index_condition              if defined $self->index_condition;
    $reply->{ 'hash_key' }            = $self->hash_key             if defined $self->hash_key;
    $reply->{ 'merge_key' }            = $self->merge_key             if defined $self->merge_key;
    $reply->{ 'filter' }            = $self->filter             if defined $self->filter;
    $reply->{ 'group_by' }            = $self->group_by             if defined $self->group_by;
    $reply->{ 'sort_key_limit' }            = $self->sort_key_limit             if defined $self->sort_key_limit;
    $reply->{ 'sort_key_distinct' }            = $self->sort_key_distinct             if defined $self->sort_key_distinct;
    $reply->{ 'sort_key' }            = $self->sort_key             if defined $self->sort_key;
    $reply->{ 'hash_chain_length_avg' }            = $self->hash_chain_length_avg             if defined $self->hash_chain_length_avg;
    $reply->{ 'hash_chain_length_max' }            = $self->hash_chain_length_max             if defined $self->hash_chain_length_max;
    $reply->{ 'hash_chain_buckets' }            = $self->hash_chain_buckets             if defined $self->hash_chain_buckets;
    $reply->{ 'hash_chain_buckets_used' }            = $self->hash_chain_buckets_used             if defined $self->hash_chain_buckets_used;

    $reply->{ 'is_analyzed' } = $self->is_analyzed;

    $reply->{ 'sub_nodes' } = [ map { $_->get_struct } @{ $self->sub_nodes } ] if defined $self->sub_nodes;
    $reply->{ 'initplans' } = [ map { $_->get_struct } @{ $self->initplans } ] if defined $self->initplans;
    $reply->{ 'subplans' }  = [ map { $_->get_struct } @{ $self->subplans } ]  if defined $self->subplans;

    $reply->{ 'cte_order' } = clone( $self->cte_order ) if defined $self->cte_order;
    if ( defined $self->ctes ) {
        $reply->{ 'ctes' } = {};
        while ( my ( $key, $cte_node ) = each %{ $self->ctes } ) {
            my $struct = $cte_node->get_struct;
            $reply->{ 'ctes' }->{ $key } = $struct;
        }
    }
    return $reply;
}

=head2 total_inclusive_time

Method for getting total node time, summarized with times of all subnodes, subplans and initplans - which is basically ->actual_loops * ->actual_time_last.

=cut

sub total_inclusive_time {
    my $self = shift;
    return unless $self->actual_loops;
    return unless defined $self->actual_time_last;
    return $self->actual_loops * $self->actual_time_last;
}

=head2 total_exclusive_time

Method for getting total node time, without times of subnodes - which amounts to time PostgreSQL spent running this paricular node.

=cut

sub total_exclusive_time {
    my $self = shift;

    my $time = $self->total_inclusive_time;
    return unless defined $time;

    for my $node ( map { @{ $_ } } grep { defined $_ } ( $self->sub_nodes ) ) {
        $time -= ( $node->total_inclusive_time || 0 );
    }

    for my $init ( map { @{ $_ } } grep { defined $_ } ( $self->initplans ) ) {
        $time -= ( $init->total_inclusive_time || 0 );
    }

    for my $plan ( map { @{ $_ } } grep { defined $_ } ( $self->subplans ) ) {
        $time -= ( $plan->total_inclusive_time || 0 );
    }

    # ignore negative times - these come from rounding errors on nodes with loops > 1.
    return 0 if $time < 0;

    return $time;
}

=head2 is_analyzed

Returns 1 if the explain node it represents was generated by EXPLAIN ANALYZE. 0 otherwise.

=cut

sub is_analyzed {
    my $self = shift;

    return defined $self->actual_loops || $self->never_executed ? 1 : 0;
}

=head2 as_text

Returns textual representation of explain nodes from given node down.

This is used to build textual explains out of in-memory data structures.

=cut

sub as_text {
    my $self   = shift;
    my $prefix = shift;
    $prefix = '' unless defined $prefix;

    $prefix .= '->  ' if '' ne $prefix;
    my $prefix_on_spaces = $prefix . "  ";
    $prefix_on_spaces =~ s/[^ ]/ /g;

    my $heading_line = $self->type;

    if ( $self->scan_on ) {
        my $S = $self->scan_on;
        if ( $S->{ 'cte_name' } ) {
            $heading_line .= " on " . $S->{ 'cte_name' };
            $heading_line .= " " . $S->{ 'cte_alias' } if $S->{ 'cte_alias' };
        }
        elsif ( $S->{ 'function_name' } ) {
            $heading_line .= " on " . $S->{ 'function_name' };
            $heading_line .= " " . $S->{ 'function_alias' } if $S->{ 'function_alias' };
        }
        elsif ( $S->{ 'index_name' } ) {
            if ( $S->{ 'table_name' } ) {
                $heading_line .= " using " . $S->{ 'index_name' } . " on " . $S->{ 'table_name' };
                $heading_line .= " " . $S->{ 'table_alias' } if $S->{ 'table_alias' };
            }
            else {
                $heading_line .= " on " . $S->{ 'index_name' };
            }
        }
        else {
            $heading_line .= " on " . $S->{ 'table_name' };
            $heading_line .= " " . $S->{ 'table_alias' } if $S->{ 'table_alias' };
        }
    }
    $heading_line .= sprintf '  (cost=%.3f..%.3f rows=%s width=%d)', $self->estimated_startup_cost, $self->estimated_total_cost, $self->estimated_rows, $self->estimated_row_width;
    if ( $self->is_analyzed ) {
        my $inner;
        if ( $self->never_executed ) {
            $inner = 'never executed';
        }
        elsif ( defined $self->actual_time_last ) {
            $inner = sprintf 'actual time=%.3f..%.3f rows=%s loops=%d', $self->actual_time_first, $self->actual_time_last, $self->actual_rows, $self->actual_loops;
        }
        else {
            $inner = sprintf 'actual rows=%s loops=%d', $self->actual_rows, $self->actual_loops;
        }
        $heading_line .= " ($inner)";
    }

    my @lines = ();

    push @lines, $prefix . $heading_line;
    if ( $self->extra_info ) {
        push @lines, $prefix_on_spaces . "  " . $_ for @{ $self->extra_info };
    }
    my $textual = join( "\n", @lines ) . "\n";

    if ( $self->cte_order ) {
        for my $cte_name ( @{ $self->cte_order } ) {
            $textual .= $prefix_on_spaces . "CTE " . $cte_name . "\n";
            $textual .= $self->cte( $cte_name )->as_text( $prefix_on_spaces . "    " );
        }
    }

    if ( $self->initplans ) {
        for my $ip ( @{ $self->initplans } ) {
            $textual .= $prefix_on_spaces . "InitPlan\n";
            $textual .= $ip->as_text( $prefix_on_spaces . "  " );
        }
    }
    if ( $self->sub_nodes ) {
        $textual .= $_->as_text( $prefix_on_spaces ) for @{ $self->sub_nodes };
    }
    if ( $self->subplans ) {
        for my $ip ( @{ $self->subplans } ) {
            $textual .= $prefix_on_spaces . "SubPlan\n";
            $textual .= $ip->as_text( $prefix_on_spaces . "  " );
        }
    }
    return $textual;
}

=head2 anonymize_gathering

First stage of anonymization - gathering of all possible strings that could and should be anonymized.

=cut

sub anonymize_gathering {
    my $self       = shift;
    my $anonymizer = shift;

    if ( $self->scan_on ) {
        $anonymizer->add( values %{ $self->scan_on } );
    }

    if ( $self->cte_order ) {
        $anonymizer->add( $self->{ 'cte_order' } );
    }

    if ( $self->extra_info ) {
        for my $line ( @{ $self->extra_info } ) {
            my $copy = $line;
            if ( $copy =~ m{^Foreign File:\s+(\S.*?)\s*$} ) {
                $anonymizer->add( $1 );
                next;
            }
            next unless $copy =~ s{^((?:Join Filter|Index Cond|Recheck Cond|Hash Cond|Merge Cond|Filter|Sort Key|Output|One-Time Filter):\s+)(.*)$}{$2};
            my $prefix = $1;
            my $lexer  = $self->_make_lexer( $copy );
            while ( my $x = $lexer->() ) {
                next unless ref $x;
                $anonymizer->add( $x->[ 1 ] ) if $x->[ 0 ] =~ m{\A (?: STRING_LITERAL | QUOTED_IDENTIFIER | IDENTIFIER ) \z}x;
            }
        }
    }

    for my $key ( qw( sub_nodes initplans subplans ) ) {
        next unless $self->{ $key };
        $_->anonymize_gathering( $anonymizer ) for @{ $self->{ $key } };
    }

    if ( $self->{ 'ctes' } ) {
        $_->anonymize_gathering( $anonymizer ) for values %{ $self->{ 'ctes' } };
    }
    return;
}

=head2 _make_lexer

Helper function which creates HOP::Lexer based lexer for given line of input

=cut

sub _make_lexer {
    my $self = shift;
    my $data = shift;

    ## Got from PostgreSQL 9.2devel with:
    # SQL # with z as (
    # SQL #     select
    # SQL #         typname::text as a,
    # SQL #         oid::regtype::text as b
    # SQL #     from
    # SQL #         pg_type
    # SQL #     where
    # SQL #         typrelid = 0
    # SQL #         and typnamespace = 11
    # SQL # ),
    # SQL # d as (
    # SQL #     select a from z
    # SQL #     union
    # SQL #     select b from z
    # SQL # ),
    # SQL # f as (
    # SQL #     select distinct
    # SQL #         regexp_replace(
    # SQL #             regexp_replace(
    # SQL #                 regexp_replace( a, '^_', '' ),
    # SQL #                 E'\\[\\]$',
    # SQL #                 ''
    # SQL #             ),
    # SQL #             '^"(.*)"$',
    # SQL #             E'\\1'
    # SQL #         ) as t
    # SQL #     from
    # SQL #         d
    # SQL # )
    # SQL # select
    # SQL #     t
    # SQL # from
    # SQL #     f
    # SQL # order by
    # SQL #     length(t) desc,
    # SQL #     t asc;

    # Following regexp was generated by feeding list from above query to:
    # use Regexp::List;
    # my $q = Regexp::List->new();
    # print = $q->list2re( @_ );
    # It is faster than normal alternative regexp like:
    # (?:timestamp without time zone|timestamp with time zone|time without time zone|....|xid|xml)
    my $any_pgtype =
qr{(?-xism:(?=[abcdfgilmnoprstuvx])(?:t(?:i(?:me(?:stamp(?:\ with(?:out)?\ time\ zone|tz)?|\ with(?:out)?\ time\ zone|tz)?|nterval|d)|s(?:(?:tz)?range|vector|query)|(?:xid_snapsho|ex)t|rigger)|c(?:har(?:acter(?:\ varying)?)?|i(?:dr?|rcle)|string)|d(?:ate(?:range)?|ouble\ precision)|l(?:anguage_handler|ine|seg)|re(?:g(?:proc(?:edure)?|oper(?:ator)?|c(?:onfig|lass)|dictionary|type)|fcursor|ltime|cord|al)|p(?:o(?:lygon|int)|g_node_tree|ath)|a(?:ny(?:e(?:lement|num)|(?:non)?array|range)?|bstime|clitem)|b(?:i(?:t(?:\ varying)?|gint)|o(?:ol(?:ean)?|x)|pchar|ytea)|f(?:loat[48]|dw_handler)|in(?:t(?:2(?:vector)?|4(?:range)?|8(?:range)?|e(?:r[nv]al|ger))|et)|o(?:id(?:vector)?|paque)|n(?:um(?:range|eric)|ame)|sm(?:allint|gr)|m(?:acaddr|oney)|u(?:nknown|uid)|v(?:ar(?:char|bit)|oid)|x(?:id|ml)|gtsvector))};

    my @input_tokens = (
        [ 'STRING_LITERAL',    qr{'(?:''|[^']+)+'} ],
        [ 'PGTYPECAST',        qr{::"?_?$any_pgtype"?(?:\[\])?} ],
        [ 'QUOTED_IDENTIFIER', qr{"(?:""|[^"]+)+"} ],
        [ 'AND',               qr{\bAND\b}i ],
        [ 'ANY',               qr{\bANY\b}i ],
        [ 'ARRAY',             qr{\bARRAY\b}i ],
        [ 'AS',                qr{\bAS\b}i ],
        [ 'ASC',               qr{\bASC\b}i ],
        [ 'CASE',              qr{\bCASE\b}i ],
        [ 'CAST',              qr{\bCAST\b}i ],
        [ 'CHECK',             qr{\bCHECK\b}i ],
        [ 'COLLATE',           qr{\bCOLLATE\b}i ],
        [ 'COLUMN',            qr{\bCOLUMN\b}i ],
        [ 'CURRENT_CATALOG',   qr{\bCURRENT_CATALOG\b}i ],
        [ 'CURRENT_DATE',      qr{\bCURRENT_DATE\b}i ],
        [ 'CURRENT_ROLE',      qr{\bCURRENT_ROLE\b}i ],
        [ 'CURRENT_TIME',      qr{\bCURRENT_TIME\b}i ],
        [ 'CURRENT_TIMESTAMP', qr{\bCURRENT_TIMESTAMP\b}i ],
        [ 'CURRENT_USER',      qr{\bCURRENT_USER\b}i ],
        [ 'DEFAULT',           qr{\bDEFAULT\b}i ],
        [ 'DESC',              qr{\bDESC\b}i ],
        [ 'DISTINCT',          qr{\bDISTINCT\b}i ],
        [ 'DO',                qr{\bDO\b}i ],
        [ 'ELSE',              qr{\bELSE\b}i ],
        [ 'END',               qr{\bEND\b}i ],
        [ 'EXCEPT',            qr{\bEXCEPT\b}i ],
        [ 'FALSE',             qr{\bFALSE\b}i ],
        [ 'FETCH',             qr{\bFETCH\b}i ],
        [ 'FOR',               qr{\bFOR\b}i ],
        [ 'FOREIGN',           qr{\bFOREIGN\b}i ],
        [ 'FROM',              qr{\bFROM\b}i ],
        [ 'IN',                qr{\bIN\b}i ],
        [ 'INITIALLY',         qr{\bINITIALLY\b}i ],
        [ 'INTERSECT',         qr{\bINTERSECT\b}i ],
        [ 'INTO',              qr{\bINTO\b}i ],
        [ 'LEADING',           qr{\bLEADING\b}i ],
        [ 'LIMIT',             qr{\bLIMIT\b}i ],
        [ 'LOCALTIME',         qr{\bLOCALTIME\b}i ],
        [ 'LOCALTIMESTAMP',    qr{\bLOCALTIMESTAMP\b}i ],
        [ 'NOT',               qr{\bNOT\b}i ],
        [ 'NULL',              qr{\bNULL\b}i ],
        [ 'OFFSET',            qr{\bOFFSET\b}i ],
        [ 'ON',                qr{\bON\b}i ],
        [ 'ONLY',              qr{\bONLY\b}i ],
        [ 'OR',                qr{\bOR\b}i ],
        [ 'ORDER',             qr{\bORDER\b}i ],
        [ 'PLACING',           qr{\bPLACING\b}i ],
        [ 'PRIMARY',           qr{\bPRIMARY\b}i ],
        [ 'REFERENCES',        qr{\bREFERENCES\b}i ],
        [ 'RETURNING',         qr{\bRETURNING\b}i ],
        [ 'SESSION_USER',      qr{\bSESSION_USER\b}i ],
        [ 'SOME',              qr{\bSOME\b}i ],
        [ 'SYMMETRIC',         qr{\bSYMMETRIC\b}i ],
        [ 'THEN',              qr{\bTHEN\b}i ],
        [ 'TO',                qr{\bTO\b}i ],
        [ 'TRAILING',          qr{\bTRAILING\b}i ],
        [ 'TRUE',              qr{\bTRUE\b}i ],
        [ 'UNION',             qr{\bUNION\b}i ],
        [ 'UNIQUE',            qr{\bUNIQUE\b}i ],
        [ 'USER',              qr{\bUSER\b}i ],
        [ 'USING',             qr{\bUSING\b}i ],
        [ 'WHEN',              qr{\bWHEN\b}i ],
        [ 'WHERE',             qr{\bWHERE\b}i ],
        [ 'CAST:',             qr{::}i ],
        [ 'COMMA',             qr{,}i ],
        [ 'DOT',               qr{\.}i ],
        [ 'LEFT_PARENTHESIS',  qr{\(}i ],
        [ 'RIGHT_PARENTHESIS', qr{\)}i ],
        [ 'DOT',               qr{\.}i ],
        [ 'STAR',              qr{[*]} ],
        [ 'OP',                qr{[+=/<>!~@-]} ],
        [ 'NUM',               qr{-?(?:\d*\.\d+|\d+)} ],
        [ 'IDENTIFIER',        qr{[a-z_][a-z0-9_]*}i ],
        [ 'SPACE',             qr{\s+} ],
    );
    return string_lexer( $data, @input_tokens );
}

=head2 anonymize_substitute

Second stage of anonymization - actual changing strings into anonymized versions.

=cut

sub anonymize_substitute {
    my $self       = shift;
    my $anonymizer = shift;

    if ( $self->scan_on ) {
        while ( my ( $key, $value ) = each %{ $self->scan_on } ) {
            $self->scan_on->{ $key } = $anonymizer->anonymized( $value );
        }
    }

    if ( $self->cte_order ) {
        my @new_order = ();
        for my $cte_name ( @{ $self->cte_order } ) {
            my $new_name = $anonymizer->anonymized( $cte_name );
            push @new_order, $new_name;
            $self->ctes->{ $new_name } = delete $self->{ 'ctes' }->{ $cte_name };
        }
        $self->cte_order( \@new_order );
    }

    if ( $self->extra_info ) {
        my @new_extra_info = ();
        for my $line ( @{ $self->extra_info } ) {
            if ( $line =~ m{^(Foreign File:\s+)(\S.*?)(\s*)$} ) {
                push @new_extra_info, $1 . $anonymizer->anonymized( $2 ) . $3;
                next;
            }
            unless ( $line =~ s{^((?:Join Filter|Index Cond|Recheck Cond|Hash Cond|Merge Cond|Filter|Sort Key|Output|One-Time Filter):\s+)(.*)$}{$2} ) {
                push @new_extra_info, $line;
                next;
            }
            my $output = $1;
            my $lexer  = $self->_make_lexer( $line );
            while ( my $x = $lexer->() ) {
                if ( ref $x ) {
                    if ( $x->[ 0 ] eq 'STRING_LITERAL' ) {
                        $output .= "'" . $anonymizer->anonymized( $x->[ 1 ] ) . "'";
                    }
                    elsif ( $x->[ 0 ] eq 'QUOTED_IDENTIFIER' ) {
                        $output .= '"' . $anonymizer->anonymized( $x->[ 1 ] ) . '"';
                    }
                    elsif ( $x->[ 0 ] eq 'IDENTIFIER' ) {
                        $output .= $anonymizer->anonymized( $x->[ 1 ] );
                    }
                    else {
                        $output .= $x->[ 1 ];
                    }
                }
                else {
                    $output .= $x;
                }
            }
            push @new_extra_info, $output;
        }
        $self->{ 'extra_info' } = \@new_extra_info;
    }

    for my $key ( qw( sub_nodes initplans subplans ) ) {
        next unless $self->{ $key };
        $_->anonymize_substitute( $anonymizer ) for @{ $self->{ $key } };
    }

    if ( $self->{ 'ctes' } ) {
        $_->anonymize_substitute( $anonymizer ) for values %{ $self->{ 'ctes' } };
    }
    return;
}

=head1 AUTHOR

scott kahler <scott.kahler@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to <scott.kahler@gmail.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GP::Explain

=head1 COPYRIGHT & LICENSE

Copyright 2015 scott kahler, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of GP::Explain::Node
