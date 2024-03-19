import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:flutter/material.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Provider/CartProvider.dart';
import '../Provider/FavoriteProvider.dart';
import '../Provider/SettingProvider.dart';
import '../Provider/UserProvider.dart';
import 'HomePage.dart';
import 'Login.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';

class SubCategory extends StatefulWidget {
  final List<Product>? subList;
  final String title;
  const SubCategory({Key? key, this.subList, required this.title})
      : super(key: key);

  @override
  State<SubCategory> createState() => _SubCategoryState();
}

class _SubCategoryState extends State<SubCategory> {
  int selIndx = 0;
  List<Product> productList = [];
  List<Product> tempList = [];
  ScrollController controller = new ScrollController();
  bool _isNetworkAvail = true;
  bool isLoadingmore = true;
  String? totalProduct;
  String sortBy = 'p.id', orderBy = "DESC";
  List<TextEditingController> _controller = [];
  List<String>? tagList = [];
  bool _isLoading = true, _isProgress = false;

  @override
  void initState() {
    getProduct("0");
    super.initState();
  }

  void getProduct(String top) async {
    //_currentRangeValues.start.round().toString(),
    // _currentRangeValues.end.round().toString(),
    _isLoading = true;
    Map parameter = {
      SORT: sortBy,
      ORDER: orderBy,
      LIMIT: perPage.toString(),
      OFFSET: '0',
      TOP_RETAED: top,
    };

    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    String? curPin = await settingsProvider.getPrefrence("ZIPCODE") ?? "";
    //  print(curPin +"ZIPCODEE");
    if (curPin != '') parameter[ZIPCODE] = curPin;

    parameter[CATID] = widget.subList?[selIndx].id ?? '';

    if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;

    apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        total = int.parse(getdata["total"]);

        if (true) {
          tempList.clear();

          var data = getdata["data"];

          print("Product List Data ====================> : $data");
          tempList =
              (data as List).map((data) => new Product.fromJson(data)).toList();

          if (getdata.containsKey(TAG)) {
            List<String> tempList = List<String>.from(getdata[TAG]);
            if (tempList != null && tempList.length > 0) tagList = tempList;
          }

          getAvailVarient();

          // offset = offset + perPage;
        }
      } else {
        isLoadingmore = false;
        if (msg != "Products Not Found !") setSnackbar(msg!, context);
      }

      setState(() {
        _isLoading = false;
      });
      // context.read<ProductListProvider>().setProductLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      setState(() {
        _isLoading = false;
      });
      //context.read<ProductListProvider>().setProductLoading(false);
    });
  }

  void getAvailVarient() {
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == "2") {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == "1") {
            tempList[j].selVarient = i;

            break;
          }
        }
      }
    }
    _isLoading = false;
    productList.addAll(tempList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(widget.title, context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 22,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: widget.subList!.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() {
                    selIndx = index;
                    tempList.clear();
                    productList.clear();
                    getProduct('0');
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              width: 2,
                              color: selIndx == index
                                  ? colors.primary
                                  : Colors.transparent)),
                    ),
                    child: Text(
                      widget.subList![index].name!,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontWeight: index == selIndx
                              ? FontWeight.w600
                              : FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : productList.length == 0
                      ? getNoItem(context)
                      : ListView.builder(
                          controller: controller,
                          itemCount: productList.length,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return listItem(index);
                          },
                        )),

          // GridView.count(
          //     padding: EdgeInsets.all(20),
          //     crossAxisCount: 3,
          //     shrinkWrap: true,
          //     childAspectRatio: .75,
          //     children: List.generate(
          //       widget.subList!.length,
          //       (index) {
          //         return subCatItem(index, context);
          //       },
          //     )),
        ],
      ),
    );
  }

  subCatItem(int index, BuildContext context) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                    image: CachedNetworkImageProvider(
                        widget.subList![index].image!),
                    fadeInDuration: Duration(milliseconds: 150),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        erroWidget(50),
                    placeholder: placeHolder(50),
                  )),
            ),
          ),
          Text(
            widget.subList![index].name! + "\n",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),
      onTap: () {
        if (widget.subList![index].subList == null ||
            widget.subList![index].subList!.length == 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductList(
                  name: widget.subList![index].name,
                  id: widget.subList![index].id,
                  tag: false,
                  fromSeller: false,
                ),
              ));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubCategory(
                  subList: widget.subList![index].subList,
                  title: widget.subList![index].name ?? "",
                ),
              ));
        }
      },
    );
  }

  Widget listItem(int index) {
    if (index < productList.length) {
      Product model = productList[index];
      totalProduct = model.total;

      if (_controller.length < index + 1)
        _controller.add(new TextEditingController());

      _controller[index].text =
          model.prVarientList![model.selVarient!].cartCount!;

      List att = [], val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }

      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }

      double off = 0;
      if (model.prVarientList![model.selVarient!].disPrice! != "0") {
        off = (double.parse(model.prVarientList![model.selVarient!].price!) -
                double.parse(model.prVarientList![model.selVarient!].disPrice!))
            .toDouble();
        off = off *
            100 /
            double.parse(model.prVarientList![model.selVarient!].price!);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Hero(
                          tag: "ProList$index${model.id}",
                          child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10)),
                              child: Stack(
                                children: [
                                  FadeInImage(
                                    image: NetworkImage(model.image!),
                                    height: 125.0,
                                    width: 135.0,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
                                            erroWidget(125),
                                    placeholder: placeHolder(125),
                                  ),
                                  Positioned.fill(
                                      child: model.availability == "0"
                                          ? Container(
                                              height: 55,
                                              color: Colors.white70,
                                              // width: double.maxFinite,
                                              padding: EdgeInsets.all(2),
                                              child: Center(
                                                child: Text(
                                                  getTranslated(context,
                                                      'OUT_OF_STOCK_LBL')!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .caption!
                                                      .copyWith(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            )
                                          : Container()),
                                  (off != 0 || off != 0.0 || off != 0.00)
                                      ? Container(
                                          decoration: BoxDecoration(
                                              color: colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              off.toStringAsFixed(2) + "%",
                                              style: TextStyle(
                                                  color: colors.whiteTemp,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9),
                                            ),
                                          ),
                                          margin: EdgeInsets.all(5),
                                        )
                                      : Container()
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //       color: colors.red,
                                  //       borderRadius:
                                  //           BorderRadius.circular(10)),
                                  //   child: Padding(
                                  //     padding: const EdgeInsets.all(5.0),
                                  //     child: Text(
                                  //       off.toStringAsFixed(2) + "%",
                                  //       style: TextStyle(
                                  //           color: colors.whiteTemp,
                                  //           fontWeight: FontWeight.bold,
                                  //           fontSize: 9),
                                  //     ),
                                  //   ),
                                  //   margin: EdgeInsets.all(5),
                                  // )
                                ],
                              ))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            //mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                model.name!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              model.prVarientList![model.selVarient!]
                                              .attr_name !=
                                          null &&
                                      model.prVarientList![model.selVarient!]
                                          .attr_name!.isNotEmpty
                                  ? ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount:
                                          att.length >= 2 ? 2 : att.length,
                                      itemBuilder: (context, index) {
                                        return Row(children: [
                                          Flexible(
                                            child: Text(
                                              att[index].trim() + ":",
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .lightBlack),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 5.0),
                                            child: Text(
                                              val[index],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .lightBlack,
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                          )
                                        ]);
                                      })
                                  : Container(),
                              (model.rating! == "0" || model.rating! == "0.0")
                                  ? Container()
                                  : Row(
                                      children: [
                                        RatingBarIndicator(
                                          rating: double.parse(model.rating!),
                                          itemBuilder: (context, index) => Icon(
                                            Icons.star_rate_rounded,
                                            color: Colors.amber,
                                            //color: colors.primary,
                                          ),
                                          unratedColor:
                                              Colors.grey.withOpacity(0.5),
                                          itemCount: 5,
                                          itemSize: 18.0,
                                          direction: Axis.horizontal,
                                        ),
                                        Text(
                                          " (" + model.noOfRating! + ")",
                                          style: Theme.of(context)
                                              .textTheme
                                              .overline,
                                        )
                                      ],
                                    ),
                              Row(
                                children: <Widget>[
                                  Text(
                                      CUR_CURRENCY! +
                                          " " +
                                          price.toString() +
                                          " ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold)),
                                  Text(
                                    double.parse(model
                                                .prVarientList![
                                                    model.selVarient!]
                                                .disPrice!) !=
                                            0
                                        ? CUR_CURRENCY! +
                                            "" +
                                            model
                                                .prVarientList![
                                                    model.selVarient!]
                                                .price!
                                        : "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .overline!
                                        .copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            letterSpacing: 0,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              _controller[index].text != "0"
                                  ? Row(
                                      children: [
                                        //Spacer(),
                                        model.availability == "0"
                                            ? Container()
                                            : cartBtnList
                                                ? Row(
                                                    children: <Widget>[
                                                      Row(
                                                        children: <Widget>[
                                                          GestureDetector(
                                                            child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        8.0),
                                                                child: Icon(
                                                                  Icons.remove,
                                                                  size: 15,
                                                                ),
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              if (_isProgress ==
                                                                      false &&
                                                                  (int.parse(_controller[
                                                                              index]
                                                                          .text) >
                                                                      0))
                                                                removeFromCart(
                                                                    index);
                                                            },
                                                          ),
                                                          Container(
                                                            width: 37,
                                                            height: 20,
                                                            child: Stack(
                                                              children: [
                                                                Selector<
                                                                    CartProvider,
                                                                    Tuple2<
                                                                        List<
                                                                            dynamic>,
                                                                        List<
                                                                            dynamic>>>(
                                                                  builder:
                                                                      (context,
                                                                          data,
                                                                          child) {
                                                                    _controller[
                                                                            index]
                                                                        .text = data
                                                                            .item1
                                                                            .contains(model
                                                                                .id)
                                                                        ? data
                                                                            .item2[data.item1.indexWhere((element) =>
                                                                                element ==
                                                                                model.id)]
                                                                            .toString()
                                                                        : "0";
                                                                    return TextField(
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      readOnly:
                                                                          true,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .fontColor),
                                                                      controller:
                                                                          _controller[
                                                                              index],
                                                                      // _controller[index],
                                                                      decoration:
                                                                          InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                      ),
                                                                    );
                                                                  },
                                                                  selector: (_,
                                                                          provider) =>
                                                                      Tuple2(
                                                                          provider
                                                                              .cartIdList,
                                                                          provider
                                                                              .qtyList),
                                                                ),
                                                                // PopupMenuButton<
                                                                //     String>(
                                                                //   tooltip: '',
                                                                //   icon:
                                                                //       const Icon(
                                                                //     Icons
                                                                //         .arrow_drop_down,
                                                                //     size: 1,
                                                                //   ),
                                                                //   onSelected:
                                                                //       (String
                                                                //           value) {
                                                                //     if (_isProgress ==
                                                                //         false)
                                                                //       addToCart(
                                                                //           index,
                                                                //           value);
                                                                //   },
                                                                //   itemBuilder:
                                                                //       (BuildContext
                                                                //           context) {
                                                                //     return model
                                                                //         .itemsCounter!
                                                                //         .map<
                                                                //             PopupMenuItem<
                                                                //                 String>>((String
                                                                //             value) {
                                                                //       return new PopupMenuItem(
                                                                //           child: new Text(
                                                                //               value,
                                                                //               style: TextStyle(color: Theme.of(context).colorScheme.fontColor)),
                                                                //           value: value);
                                                                //     }).toList();
                                                                //   },
                                                                // ),
                                                              ],
                                                            ),
                                                          ), // ),

                                                          GestureDetector(
                                                            child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        8.0),
                                                                child: Icon(
                                                                  Icons.add,
                                                                  size: 15,
                                                                ),
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              if (_isProgress ==
                                                                  false)
                                                                addToCart(
                                                                    index,
                                                                    (int.parse(model.prVarientList![model.selVarient!].cartCount!) +
                                                                            int.parse(model.qtyStepSize!))
                                                                        .toString());
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  // model.availability == "0"
                  //     ? Text(getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                  //         style: Theme.of(context)
                  //             .textTheme
                  //             .subtitle2!
                  //             .copyWith(
                  //                 color: Colors.red,
                  //                 fontWeight: FontWeight.bold))
                  //     : Container(),
                ]),
                onTap: () {
                  Product model = productList[index];
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ProductDetail(
                              model: model,
                              index: index,
                              secPos: 0,
                              list: true,
                            )),
                  );
                },
              ),
            ),
            _controller[index].text == "0"
                ? Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: 5,
                    end: 45,
                    child: InkWell(
                      onTap: () {
                        if (_isProgress == false)
                          addToCart(
                              index,
                              (int.parse(_controller[index].text) +
                                      int.parse(model.qtyStepSize!))
                                  .toString());
                      },
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            Positioned.directional(
                textDirection: Directionality.of(context),
                bottom: 5,
                end: 0,
                child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: model.isFavLoading!
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 0.7,
                                )),
                          )
                        : Selector<FavoriteProvider, List<String?>>(
                            builder: (context, data, child) {
                              return InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    !data.contains(model.id)
                                        ? Icons.favorite_border
                                        : Icons.favorite,
                                    size: 20,
                                  ),
                                ),
                                onTap: () {
                                  if (CUR_USERID != null) {
                                    !data.contains(model.id)
                                        ? _setFav(-1, model)
                                        : _removeFav(-1, model);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Login()),
                                    );
                                  }
                                },
                              );
                            },
                            selector: (_, provider) => provider.favIdList,
                          )))
          ],
        ),
      );
    } else
      return Container();
  }

  _setFav(int index, Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = true
                : productList[index].isFavLoading = true;
          });

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          index == -1 ? model.isFav = "1" : productList[index].isFav = "1";

          context.read<FavoriteProvider>().addFavItem(model);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = false
                : productList[index].isFavLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  removeFromCart(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        int qty;

        qty =
            /*      (int.parse(productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount!)*/
            (int.parse(_controller[index].text) -
                int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;
        }

        var parameter = {
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
          USER_ID: CUR_USERID,
          QTY: qty.toString()
        };

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = ;

            context.read<UserProvider>().setCartCount(data['cart_count']);
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();

            var cart = getdata["cart"];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => new SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted)
            setState(() {
              _isProgress = false;
            });
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          setState(() {
            _isProgress = false;
          });
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> addToCart(int index, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        if (int.parse(qty) < productList[index].minOrderQuntity!) {
          qty = productList[index].minOrderQuntity.toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
          QTY: qty,
          'seller_id': productList[index].seller_id ?? ''
        };
        print(parameter.toString());
        print(manageCartApi);

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();

            var cart = getdata["cart"];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => new SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }
          if (mounted)
            setState(() {
              _isProgress = false;
            });
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          if (mounted)
            setState(() {
              _isProgress = false;
            });
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _removeFav(int index, Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = true
                : productList[index].isFavLoading = true;
          });

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(removeFavApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          index == -1 ? model.isFav = "0" : productList[index].isFav = "0";
          context
              .read<FavoriteProvider>()
              .removeFavItem(model.prVarientList![0].id!);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = false
                : productList[index].isFavLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }
}
