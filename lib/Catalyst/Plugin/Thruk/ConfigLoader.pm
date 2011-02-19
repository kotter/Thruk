package Catalyst::Plugin::Thruk::ConfigLoader;

use strict;
use base 'Catalyst::Plugin::ConfigLoader';

sub finalize_config {
    my $c = shift;

    my $project_root = $c->config->{home};

    ###################################################
    # get installed plugins
    my $plugin_dir = $c->config->{'plugin_path'} || $project_root."/plugins/";
    for my $addon (glob($project_root.'/plugins/plugins-enabled/*/')) {
        my $addon_name = $addon;
        $addon_name =~ s/\/$//gmx;
        $addon_name =~ s/^.*\///gmx;

        # does the plugin directory exist?
        if(! -d $project_root.'/root/thruk/plugins/') {
            mkdir($project_root.'/root/thruk/plugins/') or die('cannot create '.$project_root.'/root/thruk/plugins/ : '.$!);
        }

        print STDERR "loading plugin: ".$addon_name."\n" if $ENV{'THRUK_PLUGIN_DEBUG'};

        # lib directory included?
        if(-d $addon.'lib') {
            print STDERR " -> lib\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
            unshift(@INC, $addon.'lib')
        }

        # template directory included?
        if(-d $addon.'templates') {
            print STDERR " -> templates\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
            unshift @{$c->config->{templates_paths}}, $addon.'templates'
        }

        # static content included?
        if( -d $addon.'root' and -w $project_root.'/root/thruk/plugins/' ) {
            print STDERR " -> root\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
            my $target_symlink = $project_root.'/root/thruk/plugins/'.$addon_name;
            if(-e $target_symlink) { unlink($target_symlink) or die("cannot unlink: ".$target_symlink." : $!"); }
            symlink($addon.'root', $target_symlink) or die("cannot create ".$target_symlink." : ".$!);
        }
    }

    ###################################################
    # set tmp dir
    # use uid to make tmp dir more uniq
    my $tmp_dir = $c->config->{'tmp_path'} || '/tmp';
    $c->config->{'View::TT'}->{'COMPILE_DIR'} = $tmp_dir.'/thruk_ttc_'.$>;

    return;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Thruk::ConfigLoader - rearrange config just before application starts

=head1 SYNOPSIS

    use Catalyst qw[Thruk::ConfigLoader];


=head1 DESCRIPTION

Used to set and change some config options after the config has been loaded but
before the application has started

=head1 OVERLOADED METHODS

=over

=item finalize_config

rearrange config

=back

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHORS

Sven Nierlein, 2011, <nierlein@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut