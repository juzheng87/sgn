package CXGN::Phenotypes::Analysis;

=head1 NAME

CXGN::Phenotypes::Analysis - an object to handle running R package analysis on a phenotype matrix. Uses SearchFactory to handle searching native database or materialized views. This object has methods which call specific R package functions and then formats the outputs to an out file.

=head1 USAGE

my $phenotypes_analysis = CXGN::Phenotypes::Analysis->new(
    out_file_name=>$file_name,
    out_directory=>$out_dir,
    bcs_schema=>$schema,
    search_type=>$search_type,
    data_level=>$data_level,
    trait_list=>$trait_list,
    trial_list=>$trial_list,
    year_list=>$year_list,
    location_list=>$location_list,
    accession_list=>$accession_list,
    plot_list=>$plot_list,
    plant_list=>$plant_list,
    include_timestamp=>$include_timestamp,
    trait_contains=>$trait_contains,
    phenotype_min_value=>$phenotype_min_value,
    phenotype_max_value=>$phenotype_max_value,
    limit=>$limit,
    offset=>$offset
);
my $out_file = $phenotypes_analysis->get_histogram();
my $out_file = $phenotypes_analysis->get_corr_plot();
my $out_file = $phenotypes_analysis->get_heatmap();

=head1 DESCRIPTION


=head1 AUTHORS


=cut

use strict;
use warnings;
use Moose;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::Stock::StockLookup;
use CXGN::Phenotypes::SearchFactory;
use Statistics::Basic qw(:all);
use Statistics::R;
use CXGN::Phenotypes::SearchFactory;

has 'bcs_schema' => (
    isa => 'Bio::Chado::Schema',
    is => 'rw',
    required => 1,
);

#(Native or MaterializedView)
has 'search_type' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has 'out_file_name' => (
    isa => 'Str',
    is => 'ro',
    required => 1
);

has 'out_directory' => (
    isa => 'Str',
    is => 'ro',
    required => 1
);

#(plot, plant, or all)
has 'data_level' => (
    isa => 'Str|Undef',
    is => 'ro',
);

has 'trial_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'trait_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'accession_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'plot_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'plant_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'location_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'year_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'rw',
);

has 'include_timestamp' => (
    isa => 'Bool|Undef',
    is => 'ro',
    default => 0
);

has 'trait_contains' => (
    isa => 'ArrayRef[Str]|Undef',
    is => 'rw'
);

has 'phenotype_min_value' => (
    isa => 'Str|Undef',
    is => 'rw'
);

has 'phenotype_max_value' => (
    isa => 'Str|Undef',
    is => 'rw'
);

has 'limit' => (
    isa => 'Int|Undef',
    is => 'rw'
);

has 'offset' => (
    isa => 'Int|Undef',
    is => 'rw'
);

has 'include_design_info' => (
    isa => 'Bool|Undef',
    is => 'ro',
    default => 1
);

sub _get_phenotype_matrix {
    my $self = shift;
    my $phenotypes_search = CXGN::Phenotypes::PhenotypeMatrix->new(
        bcs_schema=>$schema,
        search_type=>$search_type,
        data_level=>$data_level,
        trait_list=>$trait_list,
        trial_list=>$trial_list,
        year_list=>$year_list,
        location_list=>$location_list,
        accession_list=>$accession_list,
        plot_list=>$plot_list,
        plant_list=>$plant_list,
        include_timestamp=>$include_timestamp,
        trait_contains=>$trait_contains,
        phenotype_min_value=>$phenotype_min_value,
        phenotype_max_value=>$phenotype_max_value,
        limit=>$limit,
        offset=>$offset,
        include_design_info=>1
    );
    my @data = $phenotypes_search->get_phenotype_matrix();
    return @data;
}

sub get_histogram {
    my $self = shift;
    my $out_file
    my @data = $self->_get_phenotype_matrix();

    my $R = Statistics::R->new();
    my $out1 = $R->run(
        qq`data<-read.delim(exp <- "$opt_c", header=TRUE)`,
        qq`rownames(data)<-data[,1]`,
        qq`data<-data[,-1]`,
        qq`minexp <- 0`,
        qq`CorrMat<-as.data.frame(cor(t(data[rowSums(data)>minexp,]), method="spearman"))`,
        qq`write.table(CorrMat, file="$opt_f", sep="\t")`,
    );

}

1;
