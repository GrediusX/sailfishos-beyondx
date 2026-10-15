Name:       parse-android-dynparts
Summary:    Print dmsetup tables for Android dynamic (super) partitions
Version:    0.1
Release:    1
License:    ASL 2.0
URL:        https://github.com/tchebb/parse-android-dynparts
Source0:    %{name}-%{version}.tar.bz2
BuildRequires: cmake
BuildRequires: gcc-c++
BuildRequires: pkgconfig(openssl)
Requires:   device-mapper

%description
Parses Android dynamic partition metadata (super / retrofit) and outputs a
dmsetup --concise table so logical partitions can be mapped with device-mapper.

%prep
%setup -q -n %{name}-%{version}

%build
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make %{?_smp_mflags}

%install
install -D -m 755 build/parse-android-dynparts %{buildroot}%{_bindir}/parse-android-dynparts

%files
%license LICENSE
%{_bindir}/parse-android-dynparts
