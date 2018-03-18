/*
    native calculate_hand_worth(const hands[], count = sizeof(hands));

    * hands[]: an array containing the cards to analyze (between 1 to 7 cards)
    * count: the number of cards to analyze (between 1 to 7 cards)
*/

static cell AMX_NATIVE_CALL n_calculate_hand_worth(AMX *amx, cell *params)
{
    cell 
        *addr = nullptr;

    amx_GetAddr(amx, params[1], &addr);
    if (addr == nullptr)
    {
        logprintf("[TPoker] The first parameter passed to calculate_hand_rank was invalid.");
        return -1;
    }

    const size_t len = static_cast<size_t>(params[2]);
    if (len > 7 || len < 1)
    {
        logprintf("[TPoker] The count argument passed to calculate_hand_rank was invalid.");
        return -1;
    }

    HandEvaluator eval;
    Hand h = Hand::empty();
    for (size_t i = 0; i < len; i++)
    {
        if (addr[i] < 0 || addr[i] > 51)
        {
            logprintf("[TPoker] Invalid hand passed to calculate_hand_rank, value: %d", static_cast<int>(addr[i]));
            return -1;
        }
        h += Hand(static_cast<unsigned int>(addr[i]));
    }

    cell rank = static_cast<cell>(eval.evaluate(h));
    
    //Royal flush
    if ((rank >> 12 == 9) && len >= 5)
    {
        bool has_ace = false, has_k = false;
        for (size_t i = 0; i < len; i++)
        {
            if (params[i] == 48 || params[i] == 49 || params[i] == 50 || params[i] == 51)
                has_ace = true;

            if (params[i] == 44 || params[i] == 45 || params[i] == 46 || params[i] == 47)
                has_k = true;

            if (has_k && has_ace) {
                rank = 0xA000; //10 << 12
                break;
            }
        }
    }
    return rank;
}