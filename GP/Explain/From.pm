package GP::Explain::From;
use strict;
use GP::Explain::Node;
use Carp;

=head1 NAME

GP::Explain::From - Base class for parsers of non-text explain formats.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

It's internal class to wrap some work. It should be used by GP::Explain, and not directly.

=head1 FUNCTIONS

=head2 new

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

=head2 parse_source

Function which parses actual plan, and constructs GP::Explain::Node objects
which represent it.

Returns Top node of query plan.

=cut

sub parse_source {
    my $self = shift;
    croak( 'This method ( parse_source ) should be overriden in child class!' );
}

=head2 normalize_node_struct

Simple function to let subclasses change the real keys that should be used when parsing structure.

This is (currently) useful only for XML parser.

=cut

sub normalize_node_struct {
    my $self   = shift;
    my $struct = shift;
    return $struct;
}

=head2 make_node_from

Converts single node from structure obtained from source into GP::Explain::Node class.

Recurses when necessary to get subnodes.

=cut

sub make_node_from {
    my $self   = shift;
    my $struct = shift;

    $struct = $self->normalize_node_struct( $struct );

    my $new_node = GP::Explain::Node->new(
        'type'                   => $struct->{ 'Node Type' },
        'estimated_startup_cost' => $struct->{ 'Startup Cost' },
        'estimated_total_cost'   => $struct->{ 'Total Cost' },
        'estimated_rows'         => $struct->{ 'Plan Rows' },
        'estimated_row_width'    => $struct->{ 'Plan Width' },
        'actual_time_first'      => $struct->{ 'Actual Startup Time' },
        'actual_time_last'       => $struct->{ 'Actual Total Time' },
        'actual_rows'            => $struct->{ 'Actual Rows' },
        'actual_loops'           => $struct->{ 'Actual Loops' },
    );
    if ( $struct->{ 'Actual Loops' } == 0 ) {
        $new_node->never_executed( 1 );
    }

    if ( $struct->{ 'Node Type' } =~ m{\A(?:Seq Scan|Bitmap Heap Scan|Append-only Scan)$} ) {
        $new_node->scan_on(
            {
                'table_name'  => $struct->{ 'Relation Name' },
                'table_alias' => $struct->{ 'Alias' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'Bitmap Index Scan' ) {
        $new_node->scan_on(
            {
                'index_name' => $struct->{ 'Index Name' },
            }
        );

    }
    elsif ( $struct->{ 'Node Type' } =~ m{\AIndex(?: Only)? Scan(?: Backward)?\z} ) {
        $new_node->scan_on(
            {
                'table_name'  => $struct->{ 'Relation Name' },
                'table_alias' => $struct->{ 'Alias' },
                'index_name'  => $struct->{ 'Index Name' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'CTE Scan' ) {
        $new_node->scan_on(
            {
                'cte_name'  => $struct->{ 'CTE Name' },
                'cte_alias' => $struct->{ 'Alias' },
            }
        );
    }

    $new_node->add_extra_info( 'Index Cond: ' . $struct->{ 'Index Cond' } ) if $struct->{ 'Index Cond' };
    $new_node->add_extra_info( 'Filter: ' . $struct->{ 'Filter' } )         if $struct->{ 'Filter' };

    if ( $struct->{ 'Plans' } ) {
        my @plans;
        if ( 'HASH' eq ref $struct->{ 'Plans' } ) {
            push @plans, $struct->{ 'Plans' };
        }
        else {
            @plans = @{ $struct->{ 'Plans' } };
        }
        for my $subplan ( @plans ) {
            my $subnode = $self->make_node_from( $subplan );
            if ( $subplan->{ 'Parent Relationship' } eq 'InitPlan' ) {
                if ( $subplan->{ 'Subplan Name' } =~ m{ \A \s* CTE \s+ (\S+) \s* \z }xsm ) {
                    $new_node->add_cte( $1, $subnode );
                }
                else {
                    $new_node->add_initplan( $subnode );
                }
            }
            elsif ( $subplan->{ 'Parent Relationship' } eq 'SubPlan' ) {
                $new_node->add_subplan( $subnode );
            }
            else {
                $new_node->add_sub_node( $subnode );
            }
        }
    }

    return $new_node;

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

1;    # End of GP::Explain::From
