package Getopt::Kingpin;
use 5.008001;
use strict;
use warnings;
use Moo;
use Getopt::Kingpin::Flag;
use Getopt::Kingpin::Arg;
use Carp;

our $VERSION = "0.01";

has flags => (
    is => 'rw',
    default => sub {return {}},
);

has args => (
    is => 'rw',
    default => sub {return []},
);

sub flag {
    my $self = shift;
    my ($name, $description) = @_;
    $self->flags({
            (map {$_ => $self->flags->{$_}} keys %{$self->flags}),
            $name => Getopt::Kingpin::Flag->new(
                name        => $name,
                description => $description,
            ),
        });
    return $self->flags->{$name};
}

sub arg {
    my $self = shift;
    my ($name, $description) = @_;
    my $arg = Getopt::Kingpin::Arg->new(
        name        => $name,
        description => $description,
    );
    $self->args([
            @{$self->args},
            $arg,
        ]);
    return $arg;
}

sub parse {
    my $self = shift;
    my @_argv = @ARGV;
    $self->_parse(@_argv);
}

sub _parse {
    my $self = shift;
    my @argv = @_;

    my $required_but_not_found = {
        map {$_->name => $_} grep {$_->_required} values %{$self->flags}
    };
    my $arg_index = 0;
    while (scalar @argv > 0) {
        my $arg = shift @argv;
        if ($arg =~ /^(?:--(?<no>no-)?(?<name>\S+?)(?<equal>=(?<value>\S+))?|-(?<short_name>\S+))$/) {
            my $name;
            if (defined $+{name}) {
                if (not exists $self->flags->{$+{name}}) {
                    croak sprintf "flag --%s is not found", $+{name};
                }
                $name = $+{name};
            } elsif (defined $+{short_name}) {
                foreach my $f (values %{$self->flags}) {
                    if (defined $f->short_name and $f->short_name eq $+{short_name}) {
                        $name = $f->name;
                    }
                }
                if (not defined $name) {
                    croak sprintf "flag -%s is not found", $+{short_name};
                }
            } else {
                croak;
            }
            delete $required_but_not_found->{$name} if exists $required_but_not_found->{$name};
            my $v = $self->flags->{$name};

            my $value;
            if ($v->type eq "bool") {
                $value = defined $+{no} ? 0 : 1;
            } elsif (defined $+{equal}) {
                $value = $+{value}
            } else {
                $value = shift @argv;
            }

            $v->set_value($value);
        } else {
            if ($arg_index < scalar @{$self->args}) {
                $self->args->[$arg_index]->value($arg);
                $arg_index++;
            }
        }
    }
    foreach my $r (values %$required_but_not_found) {
        croak sprintf "required flag --%s not provided", $r->name;
    }
    if (scalar @{$self->args} > $arg_index) {
        croak sprintf "required arg '%s' not provided", $self->args->[$arg_index]->name;
    }
}

sub get {
    my $self = shift;
    my ($target) = @_;
    my $t = $self->flags->{$target};

    return $t;
}


1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin - command line options parser (like golang kingpin)

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    $kingpin->parse;

    # perl sample.pl --name hello
    printf "name : %s\n", $name;

=head1 DESCRIPTION

Getopt::Kingpin は、コマンドラインオプションを扱うモジュールです。
Golangのkingpinのperl版になるべく作成しています。
https://github.com/alecthomas/kingpin

=head1 METHOD

=head2 new()

Create a parser object.

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    $kingpin->parse;

=head2 flag($name, $description)

Add and return Getopt::Kingpin::Flag object.

=head2 parse()

Parse @ARGV.

=head2 get($name)

Get Getopt::Kingpin::Flag instance of $name.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

