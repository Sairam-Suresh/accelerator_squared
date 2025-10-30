import 'package:accelerator_squared/util/page_title_impl_io.dart'
    if (dart.library.html) 'package:accelerator_squared/util/page_title_impl_web.dart'
    as impl;

void setPageTitle(String title) => impl.setPageTitle(title);


