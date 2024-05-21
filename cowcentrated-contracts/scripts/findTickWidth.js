
async function TickMath() {
    //const url = rpc;  // url string
    //const web3 = new Web3(new Web3.providers.HttpProvider(url));
    //let poolContract = new web3.eth.Contract(POOL, pool);
    const tokenODecimals = 18;
    const token1Decimals = 18;
    const diff = tokenODecimals - token1Decimals;
    const tick = 20946;
    const tickSpacing = 200;
    const width = 15;

    const multipler = '1e' + diff.toString();

    const lowerRangeTick = tick - (tickSpacing * width);
    const upperRangeTick = tick + (tickSpacing * width);

    const lowerRange = multipler * Math.pow(1.0001, lowerRangeTick);
    const price = multipler * Math.pow(1.0001, tick);
    const upperRange = multipler * Math.pow(1.0001, upperRangeTick);

    const perDiff = ((upperRange - price) / price) * 100;
    const perDiff2 = ((price - lowerRange) / price) * 100;

    console.log();
    console.log("//////   ////////  ////////  ////////  ////   ////");
    console.log("//   //  ///       ///       ///       ///   ///");
    console.log("//////   //////    //////    //////    /////////");
    console.log("//   //  ///       ///       ///          ///");
    console.log("/////   ///////   ///////    ///         ///");
    console.log();

    console.log(`Range is a ${perDiff.toFixed(2)}% difference in upper direction.`);
    console.log(`Range is a ${perDiff2.toFixed(2)}% difference in lower direction.`);
    console.log();
    console.log("///////////////////////////////");
    console.log();
    console.log(`Lower Range Price: ${lowerRange}. Lower Range Tick: ${lowerRangeTick}`);
    console.log();
    console.log(`Price: ${price}. Tick: ${tick}`);
    console.log();
    console.log(`Upper Range Price: ${upperRange}. Upper Range Tick: ${upperRangeTick}`);
    console.log();
    console.log("///////////////////////////////");
    console.log();
}

TickMath();