package Catalyst::Plugin::Thruk::ConfigLoader;

use strict;
use Thruk::Utils;
use base 'Catalyst::Plugin::ConfigLoader';

sub finalize_config {
    my $c = shift;

    my $project_root = $c->config->{home};

    ###################################################
    # switch user when running as root
    if(defined $ENV{'THRUK_SRC'} and $ENV{'THRUK_SRC'} eq 'CLI') {
        my($uid, $groups) = ($ENV{'THRUK_USER_ID'}, split(/,/mx, $ENV{'THRUK_GROUPS'}));
        if(defined $uid and $> == 0) {
            Thruk::Utils::switch_user($uid, $groups);
        }
    }

    ###################################################
    # get installed plugins
    my $plugin_dir = $c->config->{'plugin_path'} || $project_root."/plugins";
    $plugin_dir = $plugin_dir.'/plugins-enabled/*/';

    print STDERR "using plugins: ".$plugin_dir."\n" if $ENV{'THRUK_PLUGIN_DEBUG'};

    for my $addon (glob($plugin_dir)) {

        my $addon_name = $addon;
        $addon_name =~ s/\/+$//gmx;
        $addon_name =~ s/^.*\///gmx;

        # does the plugin directory exist?
        if(! -d $project_root.'/root/thruk/plugins/' and -w $project_root.'/root/thruk' ) {
            CORE::mkdir($project_root.'/root/thruk/plugins');
        }

        print STDERR "loading plugin: ".$addon_name."\n" if $ENV{'THRUK_PLUGIN_DEBUG'};

        # lib directory included?
        if(-d $addon.'lib') {
            print STDERR " -> lib\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
            unshift(@INC, $addon.'lib');
        }

        # template directory included?
        if(-d $addon.'templates') {
            print STDERR " -> templates\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
            unshift @{$c->config->{templates_paths}}, $addon.'templates';
        }

        # static content included?
        # only needed for development server, handled by apache aliasmatch otherwise
        if( -d $addon.'root' and -w $project_root.'/root/thruk/plugins/' ) {
            print STDERR " -> root\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
            my $target_symlink = $project_root.'/root/thruk/plugins/'.$addon_name;
            if(-e $target_symlink) {
                my @s1 = stat($target_symlink."/.");
                my @s2 = stat($addon.'root/.');
                if($s1[1] != $s2[1]) {
                    print STDERR " -> inodes mismatch, trying to delete\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
                    unlink($target_symlink) or die("failed to unlink: ".$target_symlink." : ".$!);
                }
            }
            if(!-e $target_symlink) {
                symlink($addon.'root', $target_symlink) or die("cannot create ".$target_symlink." : ".$!);
            }
        }
    }

    ###################################################
    # get installed / enabled themes
    my $themes_dir = $c->config->{'themes_path'} || $project_root."/themes";
    $themes_dir = $themes_dir.'/themes-enabled/*/';

    my @themes;
    for my $theme (sort glob($themes_dir)) {
        $theme =~ s/\/$//gmx;
        $theme =~ s/^.*\///gmx;
        print STDERR "theme -> $theme\n" if $ENV{'THRUK_PLUGIN_DEBUG'};
        push @themes, $theme;
    }

    print STDERR "using themes: ".$themes_dir."\n" if $ENV{'THRUK_PLUGIN_DEBUG'};

    $c->config->{'View::TT'}->{'PRE_DEFINE'}->{'themes'} = \@themes;

    ###################################################
    # set var / tmp dir
    # use uid to make tmp dir more uniq
    $c->config->{'var_path'} = './var'          unless defined $c->config->{'var_path'};
    $c->config->{'tmp_path'} = '/tmp/thruk_'.$> unless defined $c->config->{'tmp_path'};
    my $tmp_dir = $c->config->{'tmp_path'};
    $c->config->{'View::TT'}->{'COMPILE_DIR'} = $tmp_dir.'/ttc_'.$>;

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
