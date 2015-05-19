# Laravel Homestead Multibox

This is an experiment to use [Laravel's Homestead](https://github.com/laravel/homestead) into a [multi-machine](https://docs.vagrantup.com/v2/multi-machine/index.html) setup (db, app1, app2, etc). The idea is that each application will have it's own box and IP in order to simulate a real-world structure better. While this does work, I've found the performance to be very poor. If anyone has any suggestions/improvements, feel free to create a PR.

## Notes

* Removed VMWare support
* Removed Postgresql support
* Removed HHVM support
* Updated the way provisioning handles mysql databases. Now it will not remove a database, just add it if it's not already there.

## Install

1. Install Vagrant and VirtualBox as outlined in the original docs [here](https://github.com/laravel/homestead)
2. Add your sites and configuration options to the `Homestead.yaml` file. 

**Note:** Make sure your `db` box is first and all IP addresses start from the `192.168.20.20` address.

## Usage

``` bash
// bring up all boxes
$ vagrant up

// or bring up single boxes
$ vagrant up db
$ vagrant up app1
```

## Security

If you discover any security related issues, please email [Chris Gmyr](mailto:cmgmyr@gmail.com) instead of using the issue tracker.

## Credits

* [Taylor Otwell](https://github.com/taylorotwell) & [Laravel Homestead](https://github.com/laravel/homestead)
* [Chris Gmyr](https://github.com/cmgmyr)
* [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](license.md) for more information.