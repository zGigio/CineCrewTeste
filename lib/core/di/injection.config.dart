// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../modules/account/data/repositories/account_repository_impl.dart'
    as _i354;
import '../../modules/account/domain/repositories/account_repository.dart'
    as _i185;
import '../../modules/applications/data/repositories/application_repository_impl.dart'
    as _i702;
import '../../modules/applications/domain/repositories/application_repository.dart'
    as _i657;
import '../../modules/applications/domain/usecases/apply_to_job_usecase.dart'
    as _i546;
import '../../modules/applications/domain/usecases/respond_to_offer_usecase.dart'
    as _i997;
import '../../modules/applications/domain/usecases/update_application_status_usecase.dart'
    as _i1066;
import '../../modules/applications/presentation/cubit/job_applications_cubit.dart'
    as _i125;
import '../../modules/applications/presentation/cubit/my_applications_cubit.dart'
    as _i814;
import '../../modules/auth/data/repositories/auth_repository_impl.dart'
    as _i817;
import '../../modules/auth/domain/repositories/auth_repository.dart' as _i779;
import '../../modules/auth/presentation/cubit/session_cubit.dart' as _i389;
import '../../modules/chat/data/repositories/chat_repository_impl.dart'
    as _i696;
import '../../modules/chat/domain/repositories/chat_repository.dart' as _i165;
import '../../modules/chat/domain/usecases/send_message_usecase.dart' as _i821;
import '../../modules/chat/presentation/cubit/chat_cubit.dart' as _i697;
import '../../modules/chat/presentation/cubit/conversations_cubit.dart'
    as _i692;
import '../../modules/explore/data/repositories/explore_repository_impl.dart'
    as _i66;
import '../../modules/explore/domain/repositories/explore_repository.dart'
    as _i452;
import '../../modules/explore/domain/usecases/explore_usecases.dart' as _i11;
import '../../modules/explore/presentation/cubit/projects_cubit.dart' as _i896;
import '../../modules/explore/presentation/cubit/talent_results_cubit.dart'
    as _i553;
import '../../modules/jobs/data/repositories/job_repository_impl.dart' as _i876;
import '../../modules/jobs/domain/repositories/job_repository.dart' as _i537;
import '../../modules/jobs/domain/usecases/create_job_usecase.dart' as _i114;
import '../../modules/jobs/domain/usecases/search_jobs_usecase.dart' as _i373;
import '../../modules/jobs/presentation/cubit/job_search_cubit.dart' as _i580;
import '../../modules/jobs/presentation/cubit/recruiter_jobs_cubit.dart'
    as _i597;
import '../../modules/notifications/data/repositories/notification_repository_impl.dart'
    as _i504;
import '../../modules/notifications/domain/repositories/notification_repository.dart'
    as _i568;
import '../../modules/notifications/presentation/cubit/notifications_cubit.dart'
    as _i333;
import '../../modules/onboarding/domain/usecases/activate_profiles_usecases.dart'
    as _i814;
import '../../modules/payments/data/repositories/payment_repository_impl.dart'
    as _i1007;
import '../../modules/payments/data/repositories/wallet_repository_impl.dart'
    as _i219;
import '../../modules/payments/domain/repositories/payment_repository.dart'
    as _i1008;
import '../../modules/payments/domain/repositories/wallet_repository.dart'
    as _i789;
import '../../modules/payments/domain/usecases/escrow_usecases.dart' as _i1032;
import '../../modules/payments/domain/usecases/wallet_usecases.dart' as _i800;
import '../../modules/payments/presentation/cubit/payment_cubit.dart' as _i715;
import '../../modules/payments/presentation/cubit/wallet_cubit.dart' as _i978;
import '../../modules/portfolio/data/repositories/portfolio_repository_impl.dart'
    as _i685;
import '../../modules/portfolio/domain/repositories/portfolio_repository.dart'
    as _i670;
import '../../modules/portfolio/domain/usecases/portfolio_usecases.dart'
    as _i1035;
import '../../modules/portfolio/presentation/cubit/portfolio_cubit.dart'
    as _i874;
import '../../modules/profile/data/repositories/profile_repository_impl.dart'
    as _i529;
import '../../modules/profile/domain/repositories/profile_repository.dart'
    as _i496;
import '../../modules/reviews/data/repositories/review_repository_impl.dart'
    as _i354;
import '../../modules/reviews/domain/repositories/review_repository.dart'
    as _i605;
import '../../modules/reviews/domain/usecases/submit_review_usecase.dart'
    as _i185;
import '../../modules/talent_search/data/datasources/talent_remote_data_source.dart'
    as _i142;
import '../../modules/talent_search/data/repositories/talent_repository_impl.dart'
    as _i163;
import '../../modules/talent_search/domain/repositories/talent_repository.dart'
    as _i69;
import '../../modules/talent_search/domain/usecases/search_talents_by_radius_usecase.dart'
    as _i539;
import '../../modules/talent_search/presentation/cubit/talent_search_cubit.dart'
    as _i998;
import '../services/geocoding/geocoding_service.dart' as _i24;
import '../services/location/location_service.dart' as _i1046;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i24.GeocodingService>(() => _i24.GeocodingServiceImpl());
    gh.lazySingleton<_i1046.LocationService>(
      () => _i1046.LocationServiceImpl(),
    );
    gh.lazySingleton<_i537.JobRepository>(
      () => _i876.JobRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i165.ChatRepository>(
      () => _i696.ChatRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i789.WalletRepository>(
      () => _i219.WalletRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i142.TalentRemoteDataSource>(
      () => _i142.TalentRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i605.ReviewRepository>(
      () => _i354.ReviewRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1008.PaymentRepository>(
      () => _i1007.PaymentRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i496.ProfileRepository>(
      () => _i529.ProfileRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i568.NotificationRepository>(
      () => _i504.NotificationRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i670.PortfolioRepository>(
      () => _i685.PortfolioRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i597.RecruiterJobsCubit>(
      () => _i597.RecruiterJobsCubit(gh<_i537.JobRepository>()),
    );
    gh.factory<_i185.SubmitReviewUseCase>(
      () => _i185.SubmitReviewUseCase(gh<_i605.ReviewRepository>()),
    );
    gh.lazySingleton<_i185.AccountRepository>(
      () => _i354.AccountRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i821.SendMessageUseCase>(
      () => _i821.SendMessageUseCase(gh<_i165.ChatRepository>()),
    );
    gh.lazySingleton<_i779.AuthRepository>(
      () => _i817.AuthRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i800.SavePayoutAccountUseCase>(
      () => _i800.SavePayoutAccountUseCase(gh<_i789.WalletRepository>()),
    );
    gh.factory<_i800.RequestWithdrawalUseCase>(
      () => _i800.RequestWithdrawalUseCase(gh<_i789.WalletRepository>()),
    );
    gh.lazySingleton<_i452.ExploreRepository>(
      () => _i66.ExploreRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i657.ApplicationRepository>(
      () => _i702.ApplicationRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i69.TalentRepository>(
      () => _i163.TalentRepositoryImpl(gh<_i142.TalentRemoteDataSource>()),
    );
    gh.factory<_i539.SearchTalentsByRadiusUseCase>(
      () => _i539.SearchTalentsByRadiusUseCase(gh<_i69.TalentRepository>()),
    );
    gh.factory<_i978.WalletCubit>(
      () => _i978.WalletCubit(
        gh<_i789.WalletRepository>(),
        gh<_i800.SavePayoutAccountUseCase>(),
        gh<_i800.RequestWithdrawalUseCase>(),
      ),
    );
    gh.factory<_i333.NotificationsCubit>(
      () => _i333.NotificationsCubit(gh<_i568.NotificationRepository>()),
    );
    gh.lazySingleton<_i389.SessionCubit>(
      () => _i389.SessionCubit(
        gh<_i779.AuthRepository>(),
        gh<_i496.ProfileRepository>(),
      ),
    );
    gh.factory<_i814.ActivateProfessionalProfileUseCase>(
      () => _i814.ActivateProfessionalProfileUseCase(
        gh<_i496.ProfileRepository>(),
      ),
    );
    gh.factory<_i814.ActivateRecruiterProfileUseCase>(
      () =>
          _i814.ActivateRecruiterProfileUseCase(gh<_i496.ProfileRepository>()),
    );
    gh.factory<_i114.CreateJobUseCase>(
      () => _i114.CreateJobUseCase(gh<_i537.JobRepository>()),
    );
    gh.factory<_i373.SearchJobsUseCase>(
      () => _i373.SearchJobsUseCase(gh<_i537.JobRepository>()),
    );
    gh.factory<_i11.SearchTalentsUseCase>(
      () => _i11.SearchTalentsUseCase(gh<_i452.ExploreRepository>()),
    );
    gh.factory<_i11.SaveProjectUseCase>(
      () => _i11.SaveProjectUseCase(gh<_i452.ExploreRepository>()),
    );
    gh.factory<_i580.JobSearchCubit>(
      () => _i580.JobSearchCubit(gh<_i373.SearchJobsUseCase>()),
    );
    gh.factory<_i692.ConversationsCubit>(
      () => _i692.ConversationsCubit(gh<_i165.ChatRepository>()),
    );
    gh.factory<_i1035.AddPortfolioPhotoUseCase>(
      () => _i1035.AddPortfolioPhotoUseCase(gh<_i670.PortfolioRepository>()),
    );
    gh.factory<_i1035.AddPortfolioVideoUseCase>(
      () => _i1035.AddPortfolioVideoUseCase(gh<_i670.PortfolioRepository>()),
    );
    gh.factory<_i1035.SaveExperienceUseCase>(
      () => _i1035.SaveExperienceUseCase(gh<_i670.PortfolioRepository>()),
    );
    gh.factory<_i1032.PayEscrowUseCase>(
      () => _i1032.PayEscrowUseCase(gh<_i1008.PaymentRepository>()),
    );
    gh.factory<_i1032.ConfirmServiceUseCase>(
      () => _i1032.ConfirmServiceUseCase(gh<_i1008.PaymentRepository>()),
    );
    gh.factory<_i1032.OpenDisputeUseCase>(
      () => _i1032.OpenDisputeUseCase(gh<_i1008.PaymentRepository>()),
    );
    gh.factory<_i874.PortfolioCubit>(
      () => _i874.PortfolioCubit(
        gh<_i670.PortfolioRepository>(),
        gh<_i1035.AddPortfolioPhotoUseCase>(),
        gh<_i1035.AddPortfolioVideoUseCase>(),
        gh<_i1035.SaveExperienceUseCase>(),
      ),
    );
    gh.factory<_i998.TalentSearchCubit>(
      () => _i998.TalentSearchCubit(gh<_i539.SearchTalentsByRadiusUseCase>()),
    );
    gh.factory<_i546.ApplyToJobUseCase>(
      () => _i546.ApplyToJobUseCase(gh<_i657.ApplicationRepository>()),
    );
    gh.factory<_i997.RespondToOfferUseCase>(
      () => _i997.RespondToOfferUseCase(gh<_i657.ApplicationRepository>()),
    );
    gh.factory<_i1066.UpdateApplicationStatusUseCase>(
      () => _i1066.UpdateApplicationStatusUseCase(
        gh<_i657.ApplicationRepository>(),
      ),
    );
    gh.factory<_i697.ChatCubit>(
      () => _i697.ChatCubit(
        gh<_i165.ChatRepository>(),
        gh<_i821.SendMessageUseCase>(),
      ),
    );
    gh.factory<_i553.TalentResultsCubit>(
      () => _i553.TalentResultsCubit(gh<_i11.SearchTalentsUseCase>()),
    );
    gh.factory<_i715.PaymentCubit>(
      () => _i715.PaymentCubit(
        gh<_i1008.PaymentRepository>(),
        gh<_i1032.PayEscrowUseCase>(),
        gh<_i1032.ConfirmServiceUseCase>(),
        gh<_i1032.OpenDisputeUseCase>(),
      ),
    );
    gh.factory<_i896.ProjectsCubit>(
      () => _i896.ProjectsCubit(
        gh<_i452.ExploreRepository>(),
        gh<_i11.SaveProjectUseCase>(),
      ),
    );
    gh.factory<_i125.JobApplicationsCubit>(
      () => _i125.JobApplicationsCubit(
        gh<_i657.ApplicationRepository>(),
        gh<_i1066.UpdateApplicationStatusUseCase>(),
      ),
    );
    gh.factory<_i814.MyApplicationsCubit>(
      () => _i814.MyApplicationsCubit(
        gh<_i657.ApplicationRepository>(),
        gh<_i997.RespondToOfferUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
